/*	*	*	*	*	*	*	*	*	*	*	*	*
 *			   			DMA				*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
#include "p33fxxxx.h"
	
_FOSCSEL(FNOSC_PRIPLL);
_FOSC(POSCMD_XT);
_FWDT(FWDTEN_OFF);

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *			Configuração de variáveis			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/

unsigned int buffer_adc1[1024],i1=0;
unsigned int buffer_adc2[1024],i2=0;
#define SAMPLES 512
 
/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Configuração de I/Os			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
#define	LED1	PORTDbits.RD4
#define	LED2	PORTDbits.RD5

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *		Definição de constantes/variáveis		*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
#define  MAX_CHNUM	 			1		
#define  SAMP_BUFF_SIZE	 		128
#define  NUM_CHS2SCAN			1	

int  BufferA1[MAX_CHNUM+1][SAMP_BUFF_SIZE] __attribute__((space(dma),aligned(512)));
int  BufferB1[MAX_CHNUM+1][SAMP_BUFF_SIZE] __attribute__((space(dma),aligned(512)));
int  BufferA2[MAX_CHNUM+1][SAMP_BUFF_SIZE] __attribute__((space(dma),aligned(512)));
int  BufferB2[MAX_CHNUM+1][SAMP_BUFF_SIZE] __attribute__((space(dma),aligned(512)));

#define BAUD 115200
#define FCY  40000000
#define MILLISEC FCY/10000


/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Inicialização da UART1			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void InitUART1(void)
{
 	U1MODE = 0x8000;
 	U1STA 	= 0x0000;
 	U1BRG 	= ((FCY/16)/BAUD) - 1;
 	INTCON1bits.NSTDIS = 1;	
 	U1STAbits.UTXEN = 1;	
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Inicialização do ADC1			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initAdc1(void)
{
	AD1CON1bits.FORM  = 0;		//Formato sinalizado
	AD1CON1bits.SSRC  = 2;		//Fonte de clock para amostragem: Timer
	AD1CON1bits.ASAM  = 1;		//ADC Sample Control: Amostra inicia 
	AD1CON1bits.AD12B = 0;		//10-bit de resolução
	AD1CON2bits.CSCNA = 1;		//Escolhe entradas para Scan
	AD1CON2bits.CHPS  = 0;		//Converte CH0
	AD1CON3bits.ADRC  = 0;		//Clock derivado do principal
	AD1CON3bits.ADCS  = 1;		//Clock de conversão ADC			AD1CON1bits.ADDMABM = 0; 	//Modo scatter/gather
	AD1CON2bits.SMPI    = (NUM_CHS2SCAN-1);	
	AD1CON4bits.DMABL   = 7;	//Cada buffer com 128 palavras
	AD1CSSH = 0x0000;				
	AD1CSSLbits.CSS0=1;		//Scan em AN0
	AD1PCFGL=0xFFFF;
	AD1PCFGH=0xFFFF;
	AD1PCFGLbits.PCFG0 	= 0;//AN0 como entrada analógica
	IFS0bits.AD1IF   = 0;	//Limpa flag
	IEC0bits.AD1IE   = 0;	//Desliga interrupção
	AD1CON1bits.ADON = 1;	//Liga CAD
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Inicialização do ADC2			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initAdc2(void)
{
	AD2CON1bits.FORM  = 0;		//Formato sinalizado
	AD2CON1bits.SSRC  = 2;		//Fonte de clock para amostragem: Timer
	AD2CON1bits.ASAM  = 1;		//ADC Sample Control: Amostra inicia	AD2CON1bits.AD12B = 0;		//10-bit de resolução
	AD2CON2bits.CSCNA = 1;		//Escolhe entradas para Scan
	AD2CON2bits.CHPS  = 0;		//Converte CH0
	AD2CON3bits.ADRC  = 0;		//Clock derivado do principal
	AD2CON3bits.ADCS  = 1;		//Clock de conversão ADC			AD2CON1bits.ADDMABM = 0; 	//Modo scatter/gather
	AD2CON2bits.SMPI    = (NUM_CHS2SCAN-1);	
	AD2CON4bits.DMABL   = 7;	//Cada buffer com 128 palavras
	AD2CSSLbits.CSS1=1;		//Scan em AN1
 	AD2PCFGL=0xFFFF;
	AD2PCFGLbits.PCFG1 = 0;		//AN1 como entrada analógica
	IFS1bits.AD2IF   = 0;		//Limpa flag
	IEC1bits.AD2IE   = 0;		//Desliga interrupção
	AD2CON1bits.ADON = 1;		//Liga CAD
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Inicialização do Timer3			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initTmr3(void) 
{
	PR3  = 79;				//Configura base de tempo
	T3CONbits.TON = 1;		//Liga timer3
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Inicialização do Timer3			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initTmr5(void) 
{
	PR5  = 79;				//Configura base de tempo
	T5CONbits.TON = 1;		//Liga timer5
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Inicialização do DMA			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initDma0(void)
{
	DMA0CONbits.AMODE = 2;	//Acesso indireto a DMA
	DMA0CONbits.MODE  = 2;	//Modo Ping-Pong
	DMA0PAD=(int)&ADC1BUF0;
	DMA0CNT = (SAMP_BUFF_SIZE*NUM_CHS2SCAN)-1;					
	DMA0REQ = 13;		//Seleciona ADC1 como fonte para DMA
	DMA0STA = __builtin_dmaoffset(BufferA1);		
	DMA0STB = __builtin_dmaoffset(BufferB1);
	IFS0bits.DMA0IF = 0;	//Limpa flag
	IEC0bits.DMA0IE = 1;	//Habilita interrupção de DMA
	DMA0CONbits.CHEN=1;	//Habilita DMA
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Inicialização do DMA			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initDma1(void)
{
	DMA1CONbits.AMODE = 2;	//Acesso indireto a DMA
	DMA1CONbits.MODE  = 2;	//Modo Ping-Pong
	DMA1PAD=(int)&ADC2BUF0;
	DMA1CNT = (SAMP_BUFF_SIZE*NUM_CHS2SCAN)-1;					
	DMA1REQ = 21;		//Seleciona ADC2 como fonte para DMA
	DMA1STA = __builtin_dmaoffset(BufferA2);		
	DMA1STB = __builtin_dmaoffset(BufferB2);
	IFS0bits.DMA1IF = 0;	//Limpa flag
    	IEC0bits.DMA1IE = 1;	//Habilita interrupção de DMA
	DMA1CONbits.CHEN=1;	//Habilita DMA
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *	  	        Inicialização de IOs			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initIOs(void)
{
	TRISDbits.TRISD4=0;		//Configura I/Os
	TRISDbits.TRISD5=0;
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Interrupção do DMA				*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void __attribute__((interrupt, no_auto_psv)) _DMA0Interrupt(void)
{
	static int DmaBuffer = 0;
	int i;
	
	if(DmaBuffer == 0)	
	{		
		for(i=0;i<SAMP_BUFF_SIZE;i++)
		{
			buffer_adc1[i1]=BufferA1[0][i];
			i1++;
			if(i1>=SAMPLES)
				i1=0;
		}	
	}	
	else
	{
		for(i=0;i<SAMP_BUFF_SIZE;i++)
		{
			buffer_adc1[i1]=BufferB1[0][i];
			i1++;
			if(i1>=SAMPLES)
				i1=0;
		}	
	}		

	LED1=~LED1;		
	DmaBuffer ^= 1;
	IFS0bits.DMA0IF = 0;	//Limpa flag de interrupção
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Interrupção do DMA				*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void __attribute__((interrupt, no_auto_psv)) _DMA1Interrupt(void)
{
	static int DmaBuffer = 0;
	int i;
	
	if(DmaBuffer == 0)	
	{		
		for(i=0;i<SAMP_BUFF_SIZE;i++)
		{
			buffer_adc2[i2]=BufferA2[1][i];
			i2++;
			if(i2>=SAMPLES)
				i2=0;
		}	
	}	
	else
	{
		for(i=0;i<SAMP_BUFF_SIZE;i++)
		{
			buffer_adc2[i2]=BufferB2[1][i];
			i2++;
			if(i2>=SAMPLES)
				i2=0;
		}	
	}	
			
	LED2=~LED2;
	DmaBuffer ^= 1;
	IFS0bits.DMA1IF = 0;	//Limpa flag de interrupção
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *			Inicialização de PLL				*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void initPLL(void)
{
	 CLKDIV = 0x0000;			// Divide clock = 1
 	 PLLFBD = 0x002A;			// PLL ratio = N + 43 = 45
 						// Fosc=165,6 MHz
}

/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Função de delay					*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void Delay_ms(unsigned int N)
{
	unsigned int j;
	while(N--)
 		for(j=0;j < MILLISEC;j++);
}	
  
/*	*	*	*	*	*	*	*	*	*	*	*	*
 *	   		  Função de envio de CHR			*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
void txCHR(unsigned char dado)
{
	U1TXREG=dado;
	while (!U1STAbits.TRMT);
	Delay_ms(10);		
}
	 
/*	*	*	*	*	*	*	*	*	*	*	*	*
 *				Função Principal				*
 *	*	*	*	*	*	*	*	*	*	*	*	*/
int main (void)
{
	initPLL();				//Inicializa PLL			
   	initAdc1();             //Inicializa ADC
   	initAdc2();             //Inicializa ADC
	initDma0();				//Inicializa DMA
	initDma1();				//Inicializa DMA
	initTmr3();				//Inializa Timer3
	initTmr5();				//Inializa Timer5
	initIOs();				//Inicializa IOs
	InitUART1();			//Inicializa UART
		
    while (1)               //Loop principal
    {
	   if(IFS0bits.U1RXIF)
	   {
		   	 int cont;		   	 
		   	 char dado;
		   	 dado=U1RXREG;	
		   	 IFS0bits.U1RXIF=0;
		   	 		   	 	   	 
		  	 IEC0bits.DMA0IE = 0;		  	 
		  	 IEC0bits.DMA1IE = 0;		  	 
		  	 LED1=0;
		  	 LED2=0;
		  	 
		  	 for(cont=0;cont<SAMPLES;cont++)
		  	 {	 		 	
	   		 	txCHR(buffer_adc1[cont]>>2);		//LSB
	   		 } 
	   						   		 
	   		 for(cont=0;cont<SAMPLES;cont++)
		  	 {	 		 
	   		 	txCHR(buffer_adc2[cont]>>2);		//LSB
	   		 } 
	   		 txCHR('F');
	   		 txCHR('I');	   		 
	   		 txCHR('M');
	   		 txCHR(13);	   		 
	   		 txCHR(10);
	   		 
	   		 IEC0bits.DMA0IE = 1;
	   		 IEC0bits.DMA1IE = 1;	   		 	   		 
	   }	   
    }    
}
