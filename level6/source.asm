Disassembly of section .plt:

08048330 <strcpy@plt-0x10>:
 8048330:	ff 35 04 98 04 08    	pushl  0x8049804
 8048336:	ff 25 08 98 04 08    	jmp    *0x8049808
 804833c:	00 00                	add    %al,(%eax)
	...

08048340 <strcpy@plt>:
 8048340:	ff 25 0c 98 04 08    	jmp    *0x804980c
 8048346:	68 00 00 00 00       	push   $0x0
 804834b:	e9 e0 ff ff ff       	jmp    8048330 <_init+0x3c>

08048350 <malloc@plt>:
 8048350:	ff 25 10 98 04 08    	jmp    *0x8049810
 8048356:	68 08 00 00 00       	push   $0x8
 804835b:	e9 d0 ff ff ff       	jmp    8048330 <_init+0x3c>

08048360 <puts@plt>:
 8048360:	ff 25 14 98 04 08    	jmp    *0x8049814
 8048366:	68 10 00 00 00       	push   $0x10
 804836b:	e9 c0 ff ff ff       	jmp    8048330 <_init+0x3c>

08048370 <system@plt>:
 8048370:	ff 25 18 98 04 08    	jmp    *0x8049818
 8048376:	68 18 00 00 00       	push   $0x18
 804837b:	e9 b0 ff ff ff       	jmp    8048330 <_init+0x3c>

08048380 <__gmon_start__@plt>:
 8048380:	ff 25 1c 98 04 08    	jmp    *0x804981c
 8048386:	68 20 00 00 00       	push   $0x20
 804838b:	e9 a0 ff ff ff       	jmp    8048330 <_init+0x3c>

08048390 <__libc_start_main@plt>:
 8048390:	ff 25 20 98 04 08    	jmp    *0x8049820
 8048396:	68 28 00 00 00       	push   $0x28
 804839b:	e9 90 ff ff ff       	jmp    8048330 <_init+0x3c>

Disassembly of section .text:

08048454 <n>:
 8048454:	55                   	push   %ebp
 8048455:	89 e5                	mov    %esp,%ebp
 8048457:	83 ec 18             	sub    $0x18,%esp
 804845a:	c7 04 24 b0 85 04 08 	movl   $0x80485b0,(%esp)
 8048461:	e8 0a ff ff ff       	call   8048370 <system@plt>
 8048466:	c9                   	leave  
 8048467:	c3                   	ret    

08048468 <m>:
 8048468:	55                   	push   %ebp
 8048469:	89 e5                	mov    %esp,%ebp
 804846b:	83 ec 18             	sub    $0x18,%esp
 804846e:	c7 04 24 d1 85 04 08 	movl   $0x80485d1,(%esp)
 8048475:	e8 e6 fe ff ff       	call   8048360 <puts@plt>
 804847a:	c9                   	leave  
 804847b:	c3                   	ret    

0804847c <main>:
 804847c:	55                   	push   %ebp
 804847d:	89 e5                	mov    %esp,%ebp
 804847f:	83 e4 f0             	and    $0xfffffff0,%esp
 8048482:	83 ec 20             	sub    $0x20,%esp
 8048485:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
 804848c:	e8 bf fe ff ff       	call   8048350 <malloc@plt>
 8048491:	89 44 24 1c          	mov    %eax,0x1c(%esp)
 8048495:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
 804849c:	e8 af fe ff ff       	call   8048350 <malloc@plt>
 80484a1:	89 44 24 18          	mov    %eax,0x18(%esp)
 80484a5:	ba 68 84 04 08       	mov    $0x8048468,%edx
 80484aa:	8b 44 24 18          	mov    0x18(%esp),%eax
 80484ae:	89 10                	mov    %edx,(%eax)
 80484b0:	8b 45 0c             	mov    0xc(%ebp),%eax
 80484b3:	83 c0 04             	add    $0x4,%eax
 80484b6:	8b 00                	mov    (%eax),%eax
 80484b8:	89 c2                	mov    %eax,%edx
 80484ba:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 80484be:	89 54 24 04          	mov    %edx,0x4(%esp)
 80484c2:	89 04 24             	mov    %eax,(%esp)
 80484c5:	e8 76 fe ff ff       	call   8048340 <strcpy@plt>
 80484ca:	8b 44 24 18          	mov    0x18(%esp),%eax
 80484ce:	8b 00                	mov    (%eax),%eax
 80484d0:	ff d0                	call   *%eax
 80484d2:	c9                   	leave  
 80484d3:	c3                   	ret    
 80484d4:	90                   	nop
 80484d5:	90                   	nop
 80484d6:	90                   	nop
 80484d7:	90                   	nop
 80484d8:	90                   	nop
 80484d9:	90                   	nop
 80484da:	90                   	nop
 80484db:	90                   	nop
 80484dc:	90                   	nop
 80484dd:	90                   	nop
 80484de:	90                   	nop
 80484df:	90                   	nop
