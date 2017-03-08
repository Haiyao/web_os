;------------------------------------------------------------
;Դ�������ƣ�Boot.asm
;˵��������ϵͳ�����Ҳ�����SYSTEM\LOADER.BIN�ļ���800[0]:0000h
;------------------------------------------------------------
MAB_SECTOR equ 07e0h
MAB_LOADER equ 0800h
;------------------------------------------------------------
 org 07c00h
 jmp short start  ;ƫ��0�������ǿ�ִ�е�x86ָ��
 nop
;------------------------------------------------------------
BS_OEMName: db 'MSWIN4.1' ;OEM�ַ���
BPB_BytsPerSec: dw 200h  ;ÿ�����ֽ���
BPB_SecPerClus: db 1  ;ÿ��������
BPB_RsvdSecCnt: dw 1  ;����������
BPB_NumFATs: db 2  ;FAT����
BPB_RootEntCnt: dw 0e0h  ;����Ŀ¼��
BPB_TotSec16: dw 0b40h  ;�߼���������16λ
BPB_Media: db 0F0h  ;�洢����
BPB_FATSz16: dw 9  ;ÿ��FAT��������
BPB_SecPerTrk: dw 12h  ;ÿ�ŵ�������
BPB_NumHeads: dw 2  ;��ͷ��
BPB_HiddSec: dd 0  ;����������
BPB_TotSec32: dd 0  ;�߼���������32λ
BS_DrvNum: db 0  ;��������
BS_Reserved1: db 0  ;����
BS_BootSig: db 29h  ;��չ������־
BS_VolID: dd 0  ;�����к�
BS_VolLab: db '           ' ;���ʶ��
BS_FileSysType: db 'FAT12   ' ;�ļ�ϵͳ
     ;0:�غ�
     ;2:����
     ;4:Ŀ¼
     ;6:�ļ���С
;------------------------------------------------------------
bLoader  db 'Loader...'
bLoadPath db 'SYSTEM     '
bLoadFile db 'LOADER  BIN'
bError  db 'Error!'
bOK  db 'OK!'
;------------------------------------------------------------
start:
 cli		 ;�ر��жϣ�IF=0
 mov ax,cs   ;��ʱCSΪ0000
 mov ds,ax   ;��DS��ΪCS��ͬ�ĶΣ�����Ѱַ����
 mov ax,MAB_SECTOR
 mov es,ax   ;��ES����Ϊ����λ��07E00h��
 sti		;�����жϡ�IF=1
;------------------------------------------------------------
     ;������ʾLoader...
 mov si,bLoader
 mov cx,9
_echoloader:    
 lodsb
 mov ah,0eh
 int 10h
 loop _echoloader
;------------------------------------------------------------
     ;��ʼ����׼����ȡ��Ŀ¼
 xor ax,ax
 mov word [BS_FileSysType+4],ax  ;+4����002-�û��������Ĵ�
;------------------------------------------------------------
_getlogic_0:
 call getLogic
 xor bx,bx
 call loadSector
;------------------------------------------------------------
     ;׼������Ŀ¼���ļ�
_checkpath_0:
 mov di,word [BS_FileSysType+4]
 cmp di,200h
 jnc _checkpath_3  ;������һ����
 mov al,byte [es:di]
 or al,0
 jz _error   ;��Ŀ¼����ټ��֮���Ŀ¼��
 cmp al,0E5h
 jz _checkpath_2  ;��ɾ��Ŀ¼�����
 mov cx,0bh
 or word [BS_FileSysType+0],0
 jnz _checkpath_1
 mov si,bLoadPath  ;�Ƚ�Ŀ¼����
 repz cmpsb
 jnz _checkpath_2  ;���Ʋ���ͬ��ת����һĿ¼��
 test byte [es:di],10h
 jz _error   ;�ҵ��Ĳ���Ŀ¼
 mov word [BS_FileSysType+4],40h
 mov ax,word [es:di+15] ;�����ҵ��Ŀ�ʼ�غ�
 jmp _getlogic_0  ;�Ѿ��ҵ�Ŀ¼����ʼ�����ļ�
_checkpath_1:    ;�Ƚ��ļ�����
 mov si,bLoadFile
 repz cmpsb
 jnz _checkpath_2  ;���Ʋ���ͬ��ת����һĿ¼��
 test byte [es:di],10h
 jnz _error   ;�ҵ��Ĳ����ļ�
 mov ax,word [es:di+17]
 mov word [BS_FileSysType+6],ax
 mov ax,word [es:di+15] ;�����ҵ����ļ���С�Ϳ�ʼ�غ�
 mov word [BS_FileSysType+4],300h
 jmp short _loadfile_0 ;�Ѿ���ȷ�ҵ��ļ�
_checkpath_2:    ;��һ��Ŀ¼��
 add word [BS_FileSysType+4],20h
 jmp short _checkpath_0
_checkpath_3:    ;��һ����������
 or word [BS_FileSysType+0],0
 jnz _checkpath_4  ;���������Ŀ¼�ļ�
 mov ax,word [BS_FileSysType+2]
 inc ax
 xor bx,bx
 call loadSector  ;��ȡ��Ŀ¼��һ��������
 jmp _checkpath_0
_checkpath_4:
 mov ax,word [BS_FileSysType+0]
 call getNextClus
 cmp ax,0fffh
 jz _error   ;�����һ��
 jmp _getlogic_0
;------------------------------------------------------------
_loadfile_0:
 mov word [BS_FileSysType+0],ax
 mov bx,word [BS_FileSysType+4]
 mov ax,word [BS_FileSysType+0]
 sub ax,2
 add ax,0+1+2*9+224*32/512
 call loadSector  ;��ȡ����Ӧƫ��λ��
 add word [BS_FileSysType+4],200h
 mov ax,word [BS_FileSysType+0]
 call getNextClus  ;��ȡ��һ��
 cmp ax,0fffh  ;���һ��
 jnz _loadfile_0
;------------------------------------------------------------
     ;��ɣ���ʾOK!
 mov si,bOK
 mov cx,3
_showok_0:
 lodsb
 mov ah,0eh
 int 10h
 loop _showok_0
 jmp word MAB_LOADER:100h ;Զ��ת��800[0]:0000��ִ��ָ��
;------------------------------------------------------------
     ;���ݴغŻ�ȡ��Ŀ¼����������������
getLogic:
 mov word [BS_FileSysType+0],ax
 cmp ax,2
 jnc _getlogic_1
 mov ax,0+1+2*9
 ret
_getlogic_1:
 sub ax,2
 add ax,0+1+2*9+224*32/512
 ret
;------------------------------------------------------------
     ;��ȡ��һ���غ�
getNextClus:
 push ax
 mov bx,3
 mul bx
 shr ax,1
 xor dx,dx
 mov bx,200h
 div bx
 inc ax
 push dx   ;�غ�ƫ����
 xor bx,bx
 call loadSector
 pop bx   ;�غ�ƫ����
 mov ax,word [es:bx]
 pop bx
 shr bx,1
 jc _getnextclus_0
 and ax,0fffh  ;�غ���˫��
 ret
_getnextclus_0:    ;�غ��ǵ���
 shr ax,4
 ret
;------------------------------------------------------------
     ;��ȡ������es:bx(Ԥ�ȱ��������ƫ����)
loadSector:
 mov word [BS_FileSysType+2],ax
 xor dx,dx
 div word [BPB_SecPerTrk]
 inc dx
 mov cl,dl   ;������������
 mov ax,[word BS_FileSysType+2]
 xor dx,dx
 div word [BPB_SecPerTrk]
 xor dx,dx
 div word [BPB_NumHeads]
 mov ch,al   ;��������ŵ�
 mov dh,dl   ;���������ͷ
 mov dl,byte [BS_DrvNum]
 mov ax,0201h
 int 13h
 jc _error
 ret
;------------------------------------------------------------
     ;����������ʾERROR!
_error:
 mov si,bError
 mov cx,6
_error_0:
 lodsb
 mov ah,0eh
 int 10h
 loop _error_0
 jmp short $
;------------------------------------------------------------
 times 510-($-$$) db 0
 dw 0aa55h

;------------------------------------------------------------

;Դ��Boot.asm����
;------------------------------------------------------------
