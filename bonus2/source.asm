Disassembly of section .plt:

08048350 <memcmp@plt-0x10>:
 8048350:	ff 35 54 99 04 08    	pushl  0x8049954
 8048356:	ff 25 58 99 04 08    	jmp    *0x8049958
 804835c:	00 00                	add    %al,(%eax)
	...

08048360 <memcmp@plt>:
 8048360:	ff 25 5c 99 04 08    	jmp    *0x804995c
 8048366:	68 00 00 00 00       	push   $0x0
 804836b:	e9 e0 ff ff ff       	jmp    8048350 <_init+0x38>

08048370 <strcat@plt>:
 8048370:	ff 25 60 99 04 08    	jmp    *0x8049960
 8048376:	68 08 00 00 00       	push   $0x8
 804837b:	e9 d0 ff ff ff       	jmp    8048350 <_init+0x38>

08048380 <getenv@plt>:
 8048380:	ff 25 64 99 04 08    	jmp    *0x8049964
 8048386:	68 10 00 00 00       	push   $0x10
 804838b:	e9 c0 ff ff ff       	jmp    8048350 <_init+0x38>

08048390 <puts@plt>:
 8048390:	ff 25 68 99 04 08    	jmp    *0x8049968
 8048396:	68 18 00 00 00       	push   $0x18
 804839b:	e9 b0 ff ff ff       	jmp    8048350 <_init+0x38>

080483a0 <__gmon_start__@plt>:
 80483a0:	ff 25 6c 99 04 08    	jmp    *0x804996c
 80483a6:	68 20 00 00 00       	push   $0x20
 80483ab:	e9 a0 ff ff ff       	jmp    8048350 <_init+0x38>

080483b0 <__libc_start_main@plt>:
 80483b0:	ff 25 70 99 04 08    	jmp    *0x8049970
 80483b6:	68 28 00 00 00       	push   $0x28
 80483bb:	e9 90 ff ff ff       	jmp    8048350 <_init+0x38>

080483c0 <strncpy@plt>:
 80483c0:	ff 25 74 99 04 08    	jmp    *0x8049974
 80483c6:	68 30 00 00 00       	push   $0x30
 80483cb:	e9 80 ff ff ff       	jmp    8048350 <_init+0x38>

Disassembly of section .text:

08048484 <greetuser>:
 8048484:	55                   	push   %ebp
 8048485:	89 e5                	mov    %esp,%ebp
 8048487:	83 ec 58             	sub    $0x58,%esp
 804848a:	a1 88 99 04 08       	mov    0x8049988,%eax
 804848f:	83 f8 01             	cmp    $0x1,%eax
 8048492:	74 26                	je     80484ba <greetuser+0x36>
 8048494:	83 f8 02             	cmp    $0x2,%eax
 8048497:	74 50                	je     80484e9 <greetuser+0x65>
 8048499:	85 c0                	test   %eax,%eax
 804849b:	75 6d                	jne    804850a <greetuser+0x86>
 804849d:	ba 10 87 04 08       	mov    $0x8048710,%edx
 80484a2:	8d 45 b8             	lea    -0x48(%ebp),%eax
 80484a5:	8b 0a                	mov    (%edx),%ecx
 80484a7:	89 08                	mov    %ecx,(%eax)
 80484a9:	0f b7 4a 04          	movzwl 0x4(%edx),%ecx
 80484ad:	66 89 48 04          	mov    %cx,0x4(%eax)
 80484b1:	0f b6 52 06          	movzbl 0x6(%edx),%edx
 80484b5:	88 50 06             	mov    %dl,0x6(%eax)
 80484b8:	eb 50                	jmp    804850a <greetuser+0x86>
 80484ba:	ba 17 87 04 08       	mov    $0x8048717,%edx
 80484bf:	8d 45 b8             	lea    -0x48(%ebp),%eax
 80484c2:	8b 0a                	mov    (%edx),%ecx
 80484c4:	89 08                	mov    %ecx,(%eax)
 80484c6:	8b 4a 04             	mov    0x4(%edx),%ecx
 80484c9:	89 48 04             	mov    %ecx,0x4(%eax)
 80484cc:	8b 4a 08             	mov    0x8(%edx),%ecx
 80484cf:	89 48 08             	mov    %ecx,0x8(%eax)
 80484d2:	8b 4a 0c             	mov    0xc(%edx),%ecx
 80484d5:	89 48 0c             	mov    %ecx,0xc(%eax)
 80484d8:	0f b7 4a 10          	movzwl 0x10(%edx),%ecx
 80484dc:	66 89 48 10          	mov    %cx,0x10(%eax)
 80484e0:	0f b6 52 12          	movzbl 0x12(%edx),%edx
 80484e4:	88 50 12             	mov    %dl,0x12(%eax)
 80484e7:	eb 21                	jmp    804850a <greetuser+0x86>
 80484e9:	ba 2a 87 04 08       	mov    $0x804872a,%edx
 80484ee:	8d 45 b8             	lea    -0x48(%ebp),%eax
 80484f1:	8b 0a                	mov    (%edx),%ecx
 80484f3:	89 08                	mov    %ecx,(%eax)
 80484f5:	8b 4a 04             	mov    0x4(%edx),%ecx
 80484f8:	89 48 04             	mov    %ecx,0x4(%eax)
 80484fb:	8b 4a 08             	mov    0x8(%edx),%ecx
 80484fe:	89 48 08             	mov    %ecx,0x8(%eax)
 8048501:	0f b7 52 0c          	movzwl 0xc(%edx),%edx
 8048505:	66 89 50 0c          	mov    %dx,0xc(%eax)
 8048509:	90                   	nop
 804850a:	8d 45 08             	lea    0x8(%ebp),%eax
 804850d:	89 44 24 04          	mov    %eax,0x4(%esp)
 8048511:	8d 45 b8             	lea    -0x48(%ebp),%eax
 8048514:	89 04 24             	mov    %eax,(%esp)
 8048517:	e8 54 fe ff ff       	call   8048370 <strcat@plt>
 804851c:	8d 45 b8             	lea    -0x48(%ebp),%eax
 804851f:	89 04 24             	mov    %eax,(%esp)
 8048522:	e8 69 fe ff ff       	call   8048390 <puts@plt>
 8048527:	c9                   	leave  
 8048528:	c3                   	ret    

08048529 <main>:
 8048529:	55                   	push   %ebp
 804852a:	89 e5                	mov    %esp,%ebp
 804852c:	57                   	push   %edi
 804852d:	56                   	push   %esi
 804852e:	53                   	push   %ebx
 804852f:	83 e4 f0             	and    $0xfffffff0,%esp
 8048532:	81 ec a0 00 00 00    	sub    $0xa0,%esp
 8048538:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
 804853c:	74 0a                	je     8048548 <main+0x1f>
 804853e:	b8 01 00 00 00       	mov    $0x1,%eax
 8048543:	e9 e8 00 00 00       	jmp    8048630 <main+0x107>
 8048548:	8d 5c 24 50          	lea    0x50(%esp),%ebx
 804854c:	b8 00 00 00 00       	mov    $0x0,%eax
 8048551:	ba 13 00 00 00       	mov    $0x13,%edx
 8048556:	89 df                	mov    %ebx,%edi
 8048558:	89 d1                	mov    %edx,%ecx
 804855a:	f3 ab                	rep stos %eax,%es:(%edi)
 804855c:	8b 45 0c             	mov    0xc(%ebp),%eax
 804855f:	83 c0 04             	add    $0x4,%eax
 8048562:	8b 00                	mov    (%eax),%eax
 8048564:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
 804856b:	00 
 804856c:	89 44 24 04          	mov    %eax,0x4(%esp)
 8048570:	8d 44 24 50          	lea    0x50(%esp),%eax
 8048574:	89 04 24             	mov    %eax,(%esp)
 8048577:	e8 44 fe ff ff       	call   80483c0 <strncpy@plt>
 804857c:	8b 45 0c             	mov    0xc(%ebp),%eax
 804857f:	83 c0 08             	add    $0x8,%eax
 8048582:	8b 00                	mov    (%eax),%eax
 8048584:	c7 44 24 08 20 00 00 	movl   $0x20,0x8(%esp)
 804858b:	00 
 804858c:	89 44 24 04          	mov    %eax,0x4(%esp)
 8048590:	8d 44 24 50          	lea    0x50(%esp),%eax
 8048594:	83 c0 28             	add    $0x28,%eax
 8048597:	89 04 24             	mov    %eax,(%esp)
 804859a:	e8 21 fe ff ff       	call   80483c0 <strncpy@plt>
 804859f:	c7 04 24 38 87 04 08 	movl   $0x8048738,(%esp)
 80485a6:	e8 d5 fd ff ff       	call   8048380 <getenv@plt>
 80485ab:	89 84 24 9c 00 00 00 	mov    %eax,0x9c(%esp)
 80485b2:	83 bc 24 9c 00 00 00 	cmpl   $0x0,0x9c(%esp)
 80485b9:	00 
 80485ba:	74 5c                	je     8048618 <main+0xef>
 80485bc:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
 80485c3:	00 
 80485c4:	c7 44 24 04 3d 87 04 	movl   $0x804873d,0x4(%esp)
 80485cb:	08 
 80485cc:	8b 84 24 9c 00 00 00 	mov    0x9c(%esp),%eax
 80485d3:	89 04 24             	mov    %eax,(%esp)
 80485d6:	e8 85 fd ff ff       	call   8048360 <memcmp@plt>
 80485db:	85 c0                	test   %eax,%eax
 80485dd:	75 0c                	jne    80485eb <main+0xc2>
 80485df:	c7 05 88 99 04 08 01 	movl   $0x1,0x8049988
 80485e6:	00 00 00 
 80485e9:	eb 2d                	jmp    8048618 <main+0xef>
 80485eb:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
 80485f2:	00 
 80485f3:	c7 44 24 04 40 87 04 	movl   $0x8048740,0x4(%esp)
 80485fa:	08 
 80485fb:	8b 84 24 9c 00 00 00 	mov    0x9c(%esp),%eax
 8048602:	89 04 24             	mov    %eax,(%esp)
 8048605:	e8 56 fd ff ff       	call   8048360 <memcmp@plt>
 804860a:	85 c0                	test   %eax,%eax
 804860c:	75 0a                	jne    8048618 <main+0xef>
 804860e:	c7 05 88 99 04 08 02 	movl   $0x2,0x8049988
 8048615:	00 00 00 
 8048618:	89 e2                	mov    %esp,%edx
 804861a:	8d 5c 24 50          	lea    0x50(%esp),%ebx
 804861e:	b8 13 00 00 00       	mov    $0x13,%eax
 8048623:	89 d7                	mov    %edx,%edi
 8048625:	89 de                	mov    %ebx,%esi
 8048627:	89 c1                	mov    %eax,%ecx
 8048629:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
 804862b:	e8 54 fe ff ff       	call   8048484 <greetuser>
 8048630:	8d 65 f4             	lea    -0xc(%ebp),%esp
 8048633:	5b                   	pop    %ebx
 8048634:	5e                   	pop    %esi
 8048635:	5f                   	pop    %edi
 8048636:	5d                   	pop    %ebp
 8048637:	c3                   	ret    
 8048638:	90                   	nop
 8048639:	90                   	nop
 804863a:	90                   	nop
 804863b:	90                   	nop
 804863c:	90                   	nop
 804863d:	90                   	nop
 804863e:	90                   	nop
 804863f:	90                   	nop
