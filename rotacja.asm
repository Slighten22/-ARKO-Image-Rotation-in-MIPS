# Rotacja obrazu o 90 stopni. Program powinien wczytać obraz z formatu BMP. Następnie obrócić go n razy o 90 stopni w zadanym kierunku.
# http://galera.ii.pw.edu.pl/~zsz/arko/materialy/bmp/bmp_file_format.html - format pliku .bmp

# Przemyslaw Kacperski, numer albumu 283670

.data
size:	.space	4	#rozmiar pliku
width:	.space	4	#szerokosc obrazka
height:	.space	4	#wysokosc obrazka
temp:	.space	4	#pomocniczo na pobranie danych ktorych nie potrzebujemy
which:	.space 	1	#na wybor usera w ktora strone obracamy
projectname:	.asciiz	" = ROTACJA = \n"
howmany:	.asciiz "Ile razy chcesz obrocic obrazek?\n"
whichrotation:	.asciiz "W ktora strone chcesz obrocic obrazek? Wpisz 0 - prawo lub 1 - lewo\n"
err:		.asciiz "Blad obslugi pliku! Sprawdz plik wejsciowy!\n"
success:	.asciiz "\nSukces! Sprawdz plik wyjsciowy!\n"

input:		.asciiz	"eiti.bmp"
output:		.asciiz	"eitiout.bmp"

.text
.globl main
main:
	# wypisz tytul projektu ("Rotacja") 
	la $a0, projectname
	li $v0, 4
	syscall
	# otworz plik wejsciowy 
	la $a0, input
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	# czy otwieranie pliku poprawne? (niepoprawne jesli poprzedni syscall zwraca <0, wpp w v0 bedzie deskryptor pliku)
	move $t0, $v0 # move (DEST), (SOURCE). w t0 deskryptor pliku
	bltz $t0, fileerror
	
	# ODCZYTYWANIE DANYCH (Z NAGLOWKA) Z PLIKU
	# pomijanie 2 bajtow niepotrzebnych informacji (dwa bajty zawierajace BM)
	move $a0, $t0 
	la $a1, temp # address of input buffer
	li $a2, 2 # wczytujemy 2 znaki (2 characters to read) - 2 bajty mowiace ze to plik BMP - niepotrzebne
	li $v0, 14 
	syscall
	# wczytanie rozmiaru pliku
	la $a1, size
	li $a2, 4 # rozmiar na 4 bajtach
	li $v0, 14
	syscall
	lw $t7, size # rozmiar pliku do rejestru
	# pominiecie 12 bajtow niepotrzebnych informacji (bfReserved1 - 2B(?), bfReserved2 - 2B(?), bfOffBits - 4B, biSize - 4B)
	la $a1, temp
	li $a2, 12
	li $v0, 14	
	syscall	
	# wczytanie szerokosci obrazu (4 bajty) 18 bajtow - szerokosc - wysokosc - reszta naglowka
	la $a1, width
	li $a2, 4
	li $v0, 14
	syscall		
	lw $t2, width # szerokosc obrazu do rejestru
	# wczytanie wysokosci obrazu (4 bajty)
	la $a1, height
	li $a2, 4
	li $v0, 14
	syscall		
	lw $t3, height # wysokosc obrazu do rejestru	
	# zamkniecie pliku (ODCZYT DANYCH Z NAGLOWKA)
	move $a0, $t0
	li $v0, 16
	syscall

	#WCZYTYWANIE DANYCH Z NAGLOWKA OBRAZKA I DANYCH O PIKSELACH DO PAMIECI
	#ponowne otworzenie pliku
	la $a0, input
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	#sprawdz czy otwieranie poprawne, jezeli nie to wyrzuc fileerror	
	move $t0, $v0
	bltz $t0, fileerror
	
	# Alokacja pamieci NA WSZYSTKO (sbrk)
	la $a0, ($t7) # ile bajtow potrzeba zaalokowac = rozmiar pliku
	li $v0, 9
	syscall
	move $t1, $v0	# adres bloku zaalokowanej pamieci NA CALY PLIK WEJSCIOWY do rejestru $t1
	
	# Alokacja pamieci NA SAME PIKSELE WYJSCIA (sbrk)
	subiu $t7, $t7, 54 # w $t7 rozmiar pliku
	move $a0, $t7 # ile bajtow potrzeba zaalokowac = rozmiar pliku - 54
	addiu $t7, $t7, 54
	li $v0, 9
	syscall
	move $t8, $v0	# adres bloku zaalokowanej pamieci NA PIKSELE WYJSCIA do rejestru $t8
	
	# wczytaj zawartosc CALEGO PLIKU do wczesniej alokowanej pamieci
	move $a0, $t0 # $a0 = file descriptor
	la $a1, ($t1) # $a1 = address of input buffer; adres bloku zaalokowanej pamieci
	la $a2, ($t7) # $a2 = maximum number of characters to read; w $t7 jest rozmiar pliku w bajtach
	li $v0, 14
	syscall
	
	# zamkniecie pliku
	li $v0, 16
	syscall	
	
# !!!	Schwerpunkt
	la $t4, ($t8) # robocze t8 bedzie w t4
	la $t5, 54($t1) # a robocze t1 bedzie w t5
	# wykorzystam jeszcze t6 do skladowania bajtu spod adresu wskazywanego przez t5
		
	#PADDING
	li $t6, 4 # pom
	div $t2, $t6
	mfhi $k0 # k0 - liczba bajtow paddingu na wejsciu (szer.)
	div $t3, $t6
	mfhi $k1 # k1 - liczba bajtow paddingu na wyjsciu (wys.)
	
	# zapytaj usera ktory obrot chce zrobic i ile razy
	li $v0, 4 # print string
	la $a0, howmany
	syscall
	li $v0, 5 # read integer
	syscall
	move $s6, $v0 # s6 - ile obrotow obrazka (musi byc wieksze od 0!!!)
	move $s7, $v0 # s7 pamieta STALE ile obrotow mialo byc - przyda sie do decyzji czy zamieniac wys z szer
	li $v0, 4 # print string
	la $a0, whichrotation
	syscall
	li $v0, 5 # read integer
	syscall
	move $s5, $v0 # s5 - w ktora strone obrot (0 - prawo, 1 - lewo)

	# OPTYMALIZACJA	
	li $t6, 4 # t6 roboczy
	div $s6, $t6
	mfhi $t6 # (ilosc obrotow mod 4)
	beqz $t6, zero # obrot o 360 stopni to jak brak obrotu
	beq $t6, 1, jeden
	beq $t6, 2, dwa
	beq $t6, 3, trzy
	
zero:	# tylko przepisac wszystkie piksele z wejscia na wyscie
	la $t4, ($t8) # robocze t8 bedzie w t4
	la $t5, 54($t1) # a robocze t1 bedzie w t5
	subi $t9, $t7, 54 # ILE BAJTOW PRZEPISUJEMY: t7 - rozmiar wejscia w bajtach, naglowka nie chcemy; t9 wolny
	j tylkoprzepisz
	
jeden:	li $s6, 1 # jeden obrot w podana strone
	beq $s5, 0, prawo
	beq $s5, 1, lewo
	j end # user nie podal ani 0 ani 1 (zle wybral strone)
	
dwa:	li $s6, 2 # dwa obroty w podana strone
	beq $s5, 0, prawo
	beq $s5, 1, lewo
	j end # user nie podal ani 0 ani 1 (zle wybral strone)
	
trzy:	li $s6, 1 # jeden obrot w przeciwna strone
	beqz $s5, lewo # zamiast obracac 3 razy w prawo obroc raz w lewo		
	beq $s5, 1, prawo
	j end # user nie podal ani 0 ani 1 (zle wybral strone)
	
prawo:	# OBROT W PRAWO o 90 stopni
	subi $s0, $t2, 1 # indeks zewn petli (szerokosc-1)
	mul $s2, $s0, 3 # TO BEDZIE STALE o ile bajtow sie musimy przemiescic zeby przejsc o jeden wiersz w gore
	# do tego dolozyc #PADDING wejscia
	add $s2, $s2, $k0
	
pzewn:	subi $t9, $t3, 1 # indeks wewn petli (wysokosc-1)	
	mul $s1, $s0, 3 # liczba bajtow o ktore trzeba sie przesunac = 3*indeks zewnetrzny (ktora kolumne teraz robimy)
	la $t5, 54($t1)
	add $t5, $t5, $s1 # przechodzimy do odpowiedniego miejsca w wierszu
	
pwewn:	lbu $t6, ($t5) 
	sb $t6, ($t4)
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	lbu $t6, ($t5) 
	sb $t6, ($t4)
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	lbu $t6, ($t5) 
	sb $t6, ($t4)
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	add $t5, $t5, $s2 # przechodzimy wiersz w gore
	
	subi $t9, $t9, 1
	bgez $t9, pwewn
	# wewn
	
	add $t4, $t4, $k1 #PADDING
		
	subi $s0, $s0, 1
	bgez $s0, pzewn
	#zewn
	# KONIEC ROTACJI w prawo

	#PADDING - po rotacji zamienic paddingi ze soba (padding szerokosci i "padding" wysokosci)
	move $t6, $k0
	move $k0, $k1
	move $k1, $t6
	
	# caly blok wyjsciowy (ten zaczynajacy sie pod adresem z t8) przepisac na piksele bloku wejsciowego
	la $t4, ($t8) # robocze t8 bedzie w t4
	la $t5, 54($t1) # a robocze t1 bedzie w t5
	subi $t9, $t7, 54 # ILE BAJTOW PRZEPISUJEMY: na t7 jest rozmiar wejscia w bajtach, naglowka nie chcemy; t9 wczesniej sluzyl jako indeks petli, ale teraz jest wolny
	j przepisz
	
lewo:	# OBROT W LEWO o 90 stopni
	subi $s0, $t2, 1 # indeks zewn petli (szerokosc-1)
	mul $s2, $t2, 3 # TO BEDZIE STALE o ile bajtow sie musimy przemiescic zeby przejsc o jeden wiersz w dol
	
	#PADDING
	add $s2, $s2, $k0 # musimy pominac bajty paddingowe przy przechodzeniu wiersz w dol! 
	
	# musimy jeszcze umiec przejsc przez wsyzstkie wiersze do gory! (zaczynamy od piksela przy gornej krawedzi)
	subi $t9, $t3, 1 # (wysokosc-1)
	mul $s4, $t9, $t2 # szerokosc x wysokosc-1 x 3 bajty na piksel
	mul $s4, $s4, 3
	
lzewn:	subi $t9, $t3, 1 # indeks wewn petli (wysokosc-1)
	sub $s3, $t2, $s0 # liczba bajtow o ktore trzeba sie przesunac = 3*o ile przesunelismy indeks zewnetrzny (ktora kolumne teraz robimy)
	subi $s3, $s3, 1
	mul $s1, $s3, 3
	la $t5, 54($t1)
	add $t5, $t5, $s1 # przechodzimy do odpowiedniego miejsca w wierszu

	# do tego dodac (wysokosc-1)x #PADDING wejscia
	mul $t6, $t9, $k0
	add $s4, $s4, $t6
	add $t5, $t5, $s4 # przechodzimy do piksela w odpowiednim wierszu, na samej gorze (przy gornej krawedzi)
		
lwewn:	lbu $t6, ($t5) 
	sb $t6, ($t4)
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	lbu $t6, ($t5) 
	sb $t6, ($t4)
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	lbu $t6, ($t5) 
	sb $t6, ($t4)
	subi $t5, $t5, 2
	addi $t4, $t4, 1
	sub $t5, $t5, $s2 # przechodzimy wiersz w dol
	
	subi $t9, $t9, 1
	bgez $t9, lwewn
	# wewn
		
	add $t4, $t4, $k1 #PADDING
	
	subi $s0, $s0, 1
	bgez $s0, lzewn
	#zewn
	
	#PADDING - po rotacji zamienic paddingi ze soba
	move $t6, $k0
	move $k0, $k1
	move $k1, $t6
	
	# caly blok wyjsciowy (ten zaczynajacy sie pod adresem z t8) przepisac na piksele bloku wejsciowego
	la $t4, ($t8) # robocze t8 bedzie w t4
	la $t5, 54($t1) # a robocze t1 bedzie w t5
	subi $t9, $t7, 54 # ILE BAJTOW PRZEPISUJEMY: na t7 jest rozmiar wejscia w bajtach, naglowka nie chcemy; t9 wczesniej sluzyl jako indeks petli, ale teraz jest wolny
	j przepisz

przepisz: # zapisz wynik tej rotacji do WEJSCIOWEJ zaalokowanej pamieci (tej na caly obrazek)
	# petla przepisujaca wszystkie piksele z wyjscia na wejscie	
	lbu $t6, ($t4) 
	sb $t6, ($t5)
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	subi $t9, $t9, 1
	bgtz $t9, przepisz # 
	
	# po rotacji ZAMIENIC WYSOKOSC Z SZEROKOSCIA
	move $t9, $t2 # t9 jako roboczy indeks
	move $t2, $t3 # zamieniam szerokosc z wysokoscia w rejestrach (poczatkowo w t2 szer, w t3 wys)
	move $t3, $t9
	
	la $t4, ($t8) # trzeba znowu ustawic adresy na poczatek!!
	la $t5, 54($t1)
	
	# czy krecimy jeszcze raz?
	subi $s6, $s6, 1 # zmniejszamy licznik obrotow do zrobienia (bo zrobilismy przed chwila)
	bgtz $s6, jeszczeraz
	j save # KONIEC OBRACANIA jesli licznik = 0
	
jeszczeraz: # krecimy jeszcze raz - czas okreslic w ktora strone
	bgtz $s5, lewo # s5 ma wybor usera w ktora strone obracac: 1 - lewo, 0 - prawo
	j prawo

tylkoprzepisz:	# przepusc wejscie na wyjscie jesli liczba rotacji do zrobienia = 0
	lbu $t6, ($t5) 
	sb $t6, ($t4)
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	subi $t9, $t9, 1
	bgtz $t9, tylkoprzepisz
	la $t4, ($t8) # trzeba znowu ustawic adresy na poczatek!!
	la $t5, 54($t1)
	
save:	# ZAPIS DO WYJSCIOWEGO OBRAZKA
	# otwieramy obrazek wyjsciowy
	la $a0, output
	li $a1, 9 # 0 - read; 1 - write; 9 -write with create and append
	li $a2, 0
	li $v0, 13
	syscall	
	#sprawdz czy otwieranie poprawne, jezeli nie to wyrzuc fileerror	
	move $t0, $v0 # file descriptor
	bltz $t0, fileerror
	
	# czy zamieniamy wys z szer?
	li $s5, 2
	divu $s7, $s5 # w s7 zadana ilosc obrotow
	mfhi $s5
	beqz $s5, naglParz
	
	
	# zapis NAGLOWKA do pliku wyjsciowego
#!!	zamiana wysokosci z szerokoscia	- tylko jesli zadana liczba obrotow nieparzysta! jesli parzysta nic nie zmieniac 
naglNiep: la $a0, ($t0) # file descriptor
	la $a1, ($t1) # address of buffer from which to write; adres bloku zaalokowanej pamieci
	la $a2, 18 # hardcoded(??) buffer length; ile bajtow bedziemy zapisywac TYLKO DO SZEROKOSCI
	li $v0, 15 # write to file
	syscall	
	# do szerokosci nic sie nie zmienia; teraz czas na zmiany: Za szerokosc podstawiam wysokosc
	la $a0, ($t0) # file descriptor
	la $a1, 22($t1) # address of buffer from which to write; adres bloku zaalokowanej pamieci
	la $a2, 4 # hardcoded(??) buffer length; ile bajtow bedziemy zapisywac
	li $v0, 15 # write to file
	syscall
	# a za wysokosc podstawiam szerokosc
	la $a0, ($t0) # file descriptor
	la $a1, 18($t1) # address of buffer from which to write; adres bloku zaalokowanej pamieci
	la $a2, 4 # hardcoded(??) buffer length; ile bajtow bedziemy zapisywac
	li $v0, 15 # write to file
	syscall
	# reszta info przepisana bez zmiany
	la $a0, ($t0) #
	la $a1, 26($t1) #
	la $a2, 28 #
	li $v0, 15 # write to file
	syscall
	j savePixel
	#naglNiep
	
naglParz: # liczba obrotow byla parzysta => po prostu przepisujemy naglowek
	la $a0, ($t0) # file descriptor
	la $a1, ($t1) # address of buffer from which to write; adres bloku zaalokowanej pamieci
	la $a2, 54 # hardcoded(??) buffer length; ile bajtow bedziemy zapisywac CALY NAGLOWEK
	li $v0, 15 # write to file
	syscall	
	
savePixel: # zapis DANYCH O PIKSELACH do pliku wyjsciowego
	# BEZ ZMIANY KOLEJNOSCI PIKSELI - rotacja byla juz wczesniej
	la $a1, ($t8) # address of buffer from which to write; adres bloku zaalokowanej pamieci
	subiu $t7, $t7, 54 # w $t7 rozmiar pliku; ile bajtow zapisujemy = rozmiar pliku - 54
	la $a2, ($t7) # hardcoded(??) buffer length; ile bajtow bedziemy zapisywac
	addiu $t7, $t7, 54
	li $v0, 15 # write to file
	syscall		
	
	# zamkniecie pliku
	move $a0, $t0
	li $v0, 16
	syscall	
	
	# wydrukowanie napisu o sukcesie
	li $v0, 4
	la $a0, success
	syscall
	
	j end
	
fileerror:
	li $v0, 4
	la $a0, err
	syscall	
	
end:
	li $v0, 10
	syscall
