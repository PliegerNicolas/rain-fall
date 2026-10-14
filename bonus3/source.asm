080484f4 <main>:
 80484f4:	55                   	push   %ebp
 80484f5:	89 e5                	mov    %esp,%ebp
 80484f7:	57                   	push   %edi
 80484f8:	53                   	push   %ebx
 80484f9:	83 e4 f0             	and    $0xfffffff0,%esp
 80484fc:	81 ec a0 00 00 00    	sub    $0xa0,%esp
 8048502:	ba f0 86 04 08       	mov    $0x80486f0,%edx
 8048507:	b8 f2 86 04 08       	mov    $0x80486f2,%eax
 804850c:	89 54 24 04          	mov    %edx,0x4(%esp)
 8048510:	89 04 24             	mov    %eax,(%esp)
 8048513:	e8 f8 fe ff ff       	call   8048410 <fopen@plt>
 8048518:	89 84 24 9c 00 00 00 	mov    %eax,0x9c(%esp)
 804851f:	8d 5c 24 18          	lea    0x18(%esp),%ebx
 8048523:	b8 00 00 00 00       	mov    $0x0,%eax
 8048528:	ba 21 00 00 00       	mov    $0x21,%edx
 804852d:	89 df                	mov    %ebx,%edi
 804852f:	89 d1                	mov    %edx,%ecx
 8048531:	f3 ab                	rep stos %eax,%es:(%edi)
 8048533:	83 bc 24 9c 00 00 00 	cmpl   $0x0,0x9c(%esp)
 804853a:	00 
 804853b:	74 06                	je     8048543 <main+0x4f>
 804853d:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
 8048541:	74 0a                	je     804854d <main+0x59>
 8048543:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 8048548:	e9 c8 00 00 00       	jmp    8048615 <main+0x121>
 804854d:	8d 44 24 18          	lea    0x18(%esp),%eax
 8048551:	8b 94 24 9c 00 00 00 	mov    0x9c(%esp),%edx
 8048558:	89 54 24 0c          	mov    %edx,0xc(%esp)
 804855c:	c7 44 24 08 42 00 00 	movl   $0x42,0x8(%esp)
 8048563:	00 
 8048564:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
 804856b:	00 
 804856c:	89 04 24             	mov    %eax,(%esp)
 804856f:	e8 5c fe ff ff       	call   80483d0 <fread@plt>
 8048574:	c6 44 24 59 00       	movb   $0x0,0x59(%esp)
 8048579:	8b 45 0c             	mov    0xc(%ebp),%eax
 804857c:	83 c0 04             	add    $0x4,%eax
 804857f:	8b 00                	mov    (%eax),%eax
 8048581:	89 04 24             	mov    %eax,(%esp)
 8048584:	e8 a7 fe ff ff       	call   8048430 <atoi@plt>
 8048589:	c6 44 04 18 00       	movb   $0x0,0x18(%esp,%eax,1)
 804858e:	8d 44 24 18          	lea    0x18(%esp),%eax
 8048592:	8d 50 42             	lea    0x42(%eax),%edx
 8048595:	8b 84 24 9c 00 00 00 	mov    0x9c(%esp),%eax
 804859c:	89 44 24 0c          	mov    %eax,0xc(%esp)
 80485a0:	c7 44 24 08 41 00 00 	movl   $0x41,0x8(%esp)
 80485a7:	00 
 80485a8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
 80485af:	00 
 80485b0:	89 14 24             	mov    %edx,(%esp)
 80485b3:	e8 18 fe ff ff       	call   80483d0 <fread@plt>
 80485b8:	8b 84 24 9c 00 00 00 	mov    0x9c(%esp),%eax
 80485bf:	89 04 24             	mov    %eax,(%esp)
 80485c2:	e8 f9 fd ff ff       	call   80483c0 <fclose@plt>
 80485c7:	8b 45 0c             	mov    0xc(%ebp),%eax
 80485ca:	83 c0 04             	add    $0x4,%eax
 80485cd:	8b 00                	mov    (%eax),%eax
 80485cf:	89 44 24 04          	mov    %eax,0x4(%esp)
 80485d3:	8d 44 24 18          	lea    0x18(%esp),%eax
 80485d7:	89 04 24             	mov    %eax,(%esp)
 80485da:	e8 d1 fd ff ff       	call   80483b0 <strcmp@plt>
 80485df:	85 c0                	test   %eax,%eax
 80485e1:	75 1e                	jne    8048601 <main+0x10d>
 80485e3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
 80485ea:	00 
 80485eb:	c7 44 24 04 07 87 04 	movl   $0x8048707,0x4(%esp)
 80485f2:	08 
 80485f3:	c7 04 24 0a 87 04 08 	movl   $0x804870a,(%esp)
 80485fa:	e8 21 fe ff ff       	call   8048420 <execl@plt>
 80485ff:	eb 0f                	jmp    8048610 <main+0x11c>
 8048601:	8d 44 24 18          	lea    0x18(%esp),%eax
 8048605:	83 c0 42             	add    $0x42,%eax
 8048608:	89 04 24             	mov    %eax,(%esp)
 804860b:	e8 d0 fd ff ff       	call   80483e0 <puts@plt>
 8048610:	b8 00 00 00 00       	mov    $0x0,%eax
 8048615:	8d 65 f8             	lea    -0x8(%ebp),%esp
 8048618:	5b                   	pop    %ebx
 8048619:	5f                   	pop    %edi
 804861a:	5d                   	pop    %ebp
 804861b:	c3                   	ret    
 804861c:	90                   	nop
 804861d:	90                   	nop
 804861e:	90                   	nop
 804861f:	90                   	nop
