Disassembly of section .init:

080482d4 <_init>:
 80482d4:	53                   	push   %ebx
 80482d5:	83 ec 08             	sub    $0x8,%esp
 80482d8:	e8 00 00 00 00       	call   80482dd <_init+0x9>
 80482dd:	5b                   	pop    %ebx
 80482de:	81 c3 87 14 00 00    	add    $0x1487,%ebx
 80482e4:	8b 83 fc ff ff ff    	mov    -0x4(%ebx),%eax
 80482ea:	85 c0                	test   %eax,%eax
 80482ec:	74 05                	je     80482f3 <_init+0x1f>
 80482ee:	e8 3d 00 00 00       	call   8048330 <__gmon_start__@plt>
 80482f3:	e8 08 01 00 00       	call   8048400 <frame_dummy>
 80482f8:	e8 33 02 00 00       	call   8048530 <__do_global_ctors_aux>
 80482fd:	83 c4 08             	add    $0x8,%esp
 8048300:	5b                   	pop    %ebx
 8048301:	c3                   	ret    

Disassembly of section .plt:

08048310 <memcpy@plt-0x10>:
 8048310:	ff 35 68 97 04 08    	pushl  0x8049768
 8048316:	ff 25 6c 97 04 08    	jmp    *0x804976c
 804831c:	00 00                	add    %al,(%eax)
	...

08048320 <memcpy@plt>:
 8048320:	ff 25 70 97 04 08    	jmp    *0x8049770
 8048326:	68 00 00 00 00       	push   $0x0
 804832b:	e9 e0 ff ff ff       	jmp    8048310 <_init+0x3c>

08048330 <__gmon_start__@plt>:
 8048330:	ff 25 74 97 04 08    	jmp    *0x8049774
 8048336:	68 08 00 00 00       	push   $0x8
 804833b:	e9 d0 ff ff ff       	jmp    8048310 <_init+0x3c>

08048340 <__libc_start_main@plt>:
 8048340:	ff 25 78 97 04 08    	jmp    *0x8049778
 8048346:	68 10 00 00 00       	push   $0x10
 804834b:	e9 c0 ff ff ff       	jmp    8048310 <_init+0x3c>

08048350 <execl@plt>:
 8048350:	ff 25 7c 97 04 08    	jmp    *0x804977c
 8048356:	68 18 00 00 00       	push   $0x18
 804835b:	e9 b0 ff ff ff       	jmp    8048310 <_init+0x3c>

08048360 <atoi@plt>:
 8048360:	ff 25 80 97 04 08    	jmp    *0x8049780
 8048366:	68 20 00 00 00       	push   $0x20
 804836b:	e9 a0 ff ff ff       	jmp    8048310 <_init+0x3c>

Disassembly of section .text:

08048370 <_start>:
 8048370:	31 ed                	xor    %ebp,%ebp
 8048372:	5e                   	pop    %esi
 8048373:	89 e1                	mov    %esp,%ecx
 8048375:	83 e4 f0             	and    $0xfffffff0,%esp
 8048378:	50                   	push   %eax
 8048379:	54                   	push   %esp
 804837a:	52                   	push   %edx
 804837b:	68 20 85 04 08       	push   $0x8048520
 8048380:	68 b0 84 04 08       	push   $0x80484b0
 8048385:	51                   	push   %ecx
 8048386:	56                   	push   %esi
 8048387:	68 24 84 04 08       	push   $0x8048424
 804838c:	e8 af ff ff ff       	call   8048340 <__libc_start_main@plt>
 8048391:	f4                   	hlt    
 8048392:	90                   	nop
 8048393:	90                   	nop
 8048394:	90                   	nop
 8048395:	90                   	nop
 8048396:	90                   	nop
 8048397:	90                   	nop
 8048398:	90                   	nop
 8048399:	90                   	nop
 804839a:	90                   	nop
 804839b:	90                   	nop
 804839c:	90                   	nop
 804839d:	90                   	nop
 804839e:	90                   	nop
 804839f:	90                   	nop

080483a0 <__do_global_dtors_aux>:
 80483a0:	55                   	push   %ebp
 80483a1:	89 e5                	mov    %esp,%ebp
 80483a3:	53                   	push   %ebx
 80483a4:	83 ec 04             	sub    $0x4,%esp
 80483a7:	80 3d 8c 97 04 08 00 	cmpb   $0x0,0x804978c
 80483ae:	75 3f                	jne    80483ef <__do_global_dtors_aux+0x4f>
 80483b0:	a1 90 97 04 08       	mov    0x8049790,%eax
 80483b5:	bb 90 96 04 08       	mov    $0x8049690,%ebx
 80483ba:	81 eb 8c 96 04 08    	sub    $0x804968c,%ebx
 80483c0:	c1 fb 02             	sar    $0x2,%ebx
 80483c3:	83 eb 01             	sub    $0x1,%ebx
 80483c6:	39 d8                	cmp    %ebx,%eax
 80483c8:	73 1e                	jae    80483e8 <__do_global_dtors_aux+0x48>
 80483ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 80483d0:	83 c0 01             	add    $0x1,%eax
 80483d3:	a3 90 97 04 08       	mov    %eax,0x8049790
 80483d8:	ff 14 85 8c 96 04 08 	call   *0x804968c(,%eax,4)
 80483df:	a1 90 97 04 08       	mov    0x8049790,%eax
 80483e4:	39 d8                	cmp    %ebx,%eax
 80483e6:	72 e8                	jb     80483d0 <__do_global_dtors_aux+0x30>
 80483e8:	c6 05 8c 97 04 08 01 	movb   $0x1,0x804978c
 80483ef:	83 c4 04             	add    $0x4,%esp
 80483f2:	5b                   	pop    %ebx
 80483f3:	5d                   	pop    %ebp
 80483f4:	c3                   	ret    
 80483f5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
 80483f9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

08048400 <frame_dummy>:
 8048400:	55                   	push   %ebp
 8048401:	89 e5                	mov    %esp,%ebp
 8048403:	83 ec 18             	sub    $0x18,%esp
 8048406:	a1 94 96 04 08       	mov    0x8049694,%eax
 804840b:	85 c0                	test   %eax,%eax
 804840d:	74 12                	je     8048421 <frame_dummy+0x21>
 804840f:	b8 00 00 00 00       	mov    $0x0,%eax
 8048414:	85 c0                	test   %eax,%eax
 8048416:	74 09                	je     8048421 <frame_dummy+0x21>
 8048418:	c7 04 24 94 96 04 08 	movl   $0x8049694,(%esp)
 804841f:	ff d0                	call   *%eax
 8048421:	c9                   	leave  
 8048422:	c3                   	ret    
 8048423:	90                   	nop

08048424 <main>:
 8048424:	55                   	push   %ebp
 8048425:	89 e5                	mov    %esp,%ebp
 8048427:	83 e4 f0             	and    $0xfffffff0,%esp
 804842a:	83 ec 40             	sub    $0x40,%esp
 804842d:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048430:	83 c0 04             	add    $0x4,%eax
 8048433:	8b 00                	mov    (%eax),%eax
 8048435:	89 04 24             	mov    %eax,(%esp)
 8048438:	e8 23 ff ff ff       	call   8048360 <atoi@plt>
 804843d:	89 44 24 3c          	mov    %eax,0x3c(%esp)
 8048441:	83 7c 24 3c 09       	cmpl   $0x9,0x3c(%esp)
 8048446:	7e 07                	jle    804844f <main+0x2b>
 8048448:	b8 01 00 00 00       	mov    $0x1,%eax
 804844d:	eb 54                	jmp    80484a3 <main+0x7f>
 804844f:	8b 44 24 3c          	mov    0x3c(%esp),%eax
 8048453:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
 804845a:	8b 45 0c             	mov    0xc(%ebp),%eax
 804845d:	83 c0 08             	add    $0x8,%eax
 8048460:	8b 00                	mov    (%eax),%eax
 8048462:	89 c2                	mov    %eax,%edx
 8048464:	8d 44 24 14          	lea    0x14(%esp),%eax
 8048468:	89 4c 24 08          	mov    %ecx,0x8(%esp)
 804846c:	89 54 24 04          	mov    %edx,0x4(%esp)
 8048470:	89 04 24             	mov    %eax,(%esp)
 8048473:	e8 a8 fe ff ff       	call   8048320 <memcpy@plt>
 8048478:	81 7c 24 3c 46 4c 4f 	cmpl   $0x574f4c46,0x3c(%esp)
 804847f:	57 
 8048480:	75 1c                	jne    804849e <main+0x7a>
 8048482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
 8048489:	00 
 804848a:	c7 44 24 04 80 85 04 	movl   $0x8048580,0x4(%esp)
 8048491:	08 
 8048492:	c7 04 24 83 85 04 08 	movl   $0x8048583,(%esp)
 8048499:	e8 b2 fe ff ff       	call   8048350 <execl@plt>
 804849e:	b8 00 00 00 00       	mov    $0x0,%eax
 80484a3:	c9                   	leave  
 80484a4:	c3                   	ret    
 80484a5:	90                   	nop
 80484a6:	90                   	nop
 80484a7:	90                   	nop
 80484a8:	90                   	nop
 80484a9:	90                   	nop
 80484aa:	90                   	nop
 80484ab:	90                   	nop
 80484ac:	90                   	nop
 80484ad:	90                   	nop
 80484ae:	90                   	nop
 80484af:	90                   	nop

080484b0 <__libc_csu_init>:
 80484b0:	55                   	push   %ebp
 80484b1:	57                   	push   %edi
 80484b2:	56                   	push   %esi
 80484b3:	53                   	push   %ebx
 80484b4:	e8 69 00 00 00       	call   8048522 <__i686.get_pc_thunk.bx>
 80484b9:	81 c3 ab 12 00 00    	add    $0x12ab,%ebx
 80484bf:	83 ec 1c             	sub    $0x1c,%esp
 80484c2:	8b 6c 24 30          	mov    0x30(%esp),%ebp
 80484c6:	8d bb 20 ff ff ff    	lea    -0xe0(%ebx),%edi
 80484cc:	e8 03 fe ff ff       	call   80482d4 <_init>
 80484d1:	8d 83 20 ff ff ff    	lea    -0xe0(%ebx),%eax
 80484d7:	29 c7                	sub    %eax,%edi
 80484d9:	c1 ff 02             	sar    $0x2,%edi
 80484dc:	85 ff                	test   %edi,%edi
 80484de:	74 29                	je     8048509 <__libc_csu_init+0x59>
 80484e0:	31 f6                	xor    %esi,%esi
 80484e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 80484e8:	8b 44 24 38          	mov    0x38(%esp),%eax
 80484ec:	89 2c 24             	mov    %ebp,(%esp)
 80484ef:	89 44 24 08          	mov    %eax,0x8(%esp)
 80484f3:	8b 44 24 34          	mov    0x34(%esp),%eax
 80484f7:	89 44 24 04          	mov    %eax,0x4(%esp)
 80484fb:	ff 94 b3 20 ff ff ff 	call   *-0xe0(%ebx,%esi,4)
 8048502:	83 c6 01             	add    $0x1,%esi
 8048505:	39 fe                	cmp    %edi,%esi
 8048507:	75 df                	jne    80484e8 <__libc_csu_init+0x38>
 8048509:	83 c4 1c             	add    $0x1c,%esp
 804850c:	5b                   	pop    %ebx
 804850d:	5e                   	pop    %esi
 804850e:	5f                   	pop    %edi
 804850f:	5d                   	pop    %ebp
 8048510:	c3                   	ret    
 8048511:	eb 0d                	jmp    8048520 <__libc_csu_fini>
 8048513:	90                   	nop
 8048514:	90                   	nop
 8048515:	90                   	nop
 8048516:	90                   	nop
 8048517:	90                   	nop
 8048518:	90                   	nop
 8048519:	90                   	nop
 804851a:	90                   	nop
 804851b:	90                   	nop
 804851c:	90                   	nop
 804851d:	90                   	nop
 804851e:	90                   	nop
 804851f:	90                   	nop

08048520 <__libc_csu_fini>:
 8048520:	f3 c3                	repz ret 

08048522 <__i686.get_pc_thunk.bx>:
 8048522:	8b 1c 24             	mov    (%esp),%ebx
 8048525:	c3                   	ret    
 8048526:	90                   	nop
 8048527:	90                   	nop
 8048528:	90                   	nop
 8048529:	90                   	nop
 804852a:	90                   	nop
 804852b:	90                   	nop
 804852c:	90                   	nop
 804852d:	90                   	nop
 804852e:	90                   	nop
 804852f:	90                   	nop

08048530 <__do_global_ctors_aux>:
 8048530:	55                   	push   %ebp
 8048531:	89 e5                	mov    %esp,%ebp
 8048533:	53                   	push   %ebx
 8048534:	83 ec 04             	sub    $0x4,%esp
 8048537:	a1 84 96 04 08       	mov    0x8049684,%eax
 804853c:	83 f8 ff             	cmp    $0xffffffff,%eax
 804853f:	74 13                	je     8048554 <__do_global_ctors_aux+0x24>
 8048541:	bb 84 96 04 08       	mov    $0x8049684,%ebx
 8048546:	66 90                	xchg   %ax,%ax
 8048548:	83 eb 04             	sub    $0x4,%ebx
 804854b:	ff d0                	call   *%eax
 804854d:	8b 03                	mov    (%ebx),%eax
 804854f:	83 f8 ff             	cmp    $0xffffffff,%eax
 8048552:	75 f4                	jne    8048548 <__do_global_ctors_aux+0x18>
 8048554:	83 c4 04             	add    $0x4,%esp
 8048557:	5b                   	pop    %ebx
 8048558:	5d                   	pop    %ebp
 8048559:	c3                   	ret    
 804855a:	90                   	nop
 804855b:	90                   	nop

Disassembly of section .fini:

0804855c <_fini>:
 804855c:	53                   	push   %ebx
 804855d:	83 ec 08             	sub    $0x8,%esp
 8048560:	e8 00 00 00 00       	call   8048565 <_fini+0x9>
 8048565:	5b                   	pop    %ebx
 8048566:	81 c3 ff 11 00 00    	add    $0x11ff,%ebx
 804856c:	e8 2f fe ff ff       	call   80483a0 <__do_global_dtors_aux>
 8048571:	83 c4 08             	add    $0x8,%esp
 8048574:	5b                   	pop    %ebx
 8048575:	c3                   	ret    
