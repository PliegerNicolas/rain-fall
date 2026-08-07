Disassembly of section .text:

080485f4 <main>:
 80485f4:	55                   	push   %ebp
 80485f5:	89 e5                	mov    %esp,%ebp
 80485f7:	53                   	push   %ebx
 80485f8:	83 e4 f0             	and    $0xfffffff0,%esp
 80485fb:	83 ec 20             	sub    $0x20,%esp
 80485fe:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
 8048602:	7f 0c                	jg     8048610 <main+0x1c>
 8048604:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 804860b:	e8 e0 fe ff ff       	call   80484f0 <_exit@plt>
 8048610:	c7 04 24 6c 00 00 00 	movl   $0x6c,(%esp)
 8048617:	e8 14 ff ff ff       	call   8048530 <_Znwj@plt>
 804861c:	89 c3                	mov    %eax,%ebx
 804861e:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
 8048625:	00 
 8048626:	89 1c 24             	mov    %ebx,(%esp)
 8048629:	e8 c8 00 00 00       	call   80486f6 <_ZN1NC1Ei>
 804862e:	89 5c 24 1c          	mov    %ebx,0x1c(%esp)
 8048632:	c7 04 24 6c 00 00 00 	movl   $0x6c,(%esp)
 8048639:	e8 f2 fe ff ff       	call   8048530 <_Znwj@plt>
 804863e:	89 c3                	mov    %eax,%ebx
 8048640:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
 8048647:	00 
 8048648:	89 1c 24             	mov    %ebx,(%esp)
 804864b:	e8 a6 00 00 00       	call   80486f6 <_ZN1NC1Ei>
 8048650:	89 5c 24 18          	mov    %ebx,0x18(%esp)
 8048654:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 8048658:	89 44 24 14          	mov    %eax,0x14(%esp)
 804865c:	8b 44 24 18          	mov    0x18(%esp),%eax
 8048660:	89 44 24 10          	mov    %eax,0x10(%esp)
 8048664:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048667:	83 c0 04             	add    $0x4,%eax
 804866a:	8b 00                	mov    (%eax),%eax
 804866c:	89 44 24 04          	mov    %eax,0x4(%esp)
 8048670:	8b 44 24 14          	mov    0x14(%esp),%eax
 8048674:	89 04 24             	mov    %eax,(%esp)
 8048677:	e8 92 00 00 00       	call   804870e <_ZN1N13setAnnotationEPc>
 804867c:	8b 44 24 10          	mov    0x10(%esp),%eax
 8048680:	8b 00                	mov    (%eax),%eax
 8048682:	8b 10                	mov    (%eax),%edx
 8048684:	8b 44 24 14          	mov    0x14(%esp),%eax
 8048688:	89 44 24 04          	mov    %eax,0x4(%esp)
 804868c:	8b 44 24 10          	mov    0x10(%esp),%eax
 8048690:	89 04 24             	mov    %eax,(%esp)
 8048693:	ff d2                	call   *%edx
 8048695:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 8048698:	c9                   	leave  
 8048699:	c3                   	ret    

0804869a <_Z41__static_initialization_and_destruction_0ii>:
 804869a:	55                   	push   %ebp
 804869b:	89 e5                	mov    %esp,%ebp
 804869d:	83 ec 18             	sub    $0x18,%esp
 80486a0:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
 80486a4:	75 32                	jne    80486d8 <_Z41__static_initialization_and_destruction_0ii+0x3e>
 80486a6:	81 7d 0c ff ff 00 00 	cmpl   $0xffff,0xc(%ebp)
 80486ad:	75 29                	jne    80486d8 <_Z41__static_initialization_and_destruction_0ii+0x3e>
 80486af:	c7 04 24 b4 9b 04 08 	movl   $0x8049bb4,(%esp)
 80486b6:	e8 15 fe ff ff       	call   80484d0 <_ZNSt8ios_base4InitC1Ev@plt>
 80486bb:	b8 00 85 04 08       	mov    $0x8048500,%eax
 80486c0:	c7 44 24 08 78 9b 04 	movl   $0x8049b78,0x8(%esp)
 80486c7:	08 
 80486c8:	c7 44 24 04 b4 9b 04 	movl   $0x8049bb4,0x4(%esp)
 80486cf:	08 
 80486d0:	89 04 24             	mov    %eax,(%esp)
 80486d3:	e8 d8 fd ff ff       	call   80484b0 <__cxa_atexit@plt>
 80486d8:	c9                   	leave  
 80486d9:	c3                   	ret    

080486da <_GLOBAL__sub_I_main>:
 80486da:	55                   	push   %ebp
 80486db:	89 e5                	mov    %esp,%ebp
 80486dd:	83 ec 18             	sub    $0x18,%esp
 80486e0:	c7 44 24 04 ff ff 00 	movl   $0xffff,0x4(%esp)
 80486e7:	00 
 80486e8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 80486ef:	e8 a6 ff ff ff       	call   804869a <_Z41__static_initialization_and_destruction_0ii>
 80486f4:	c9                   	leave  
 80486f5:	c3                   	ret    

080486f6 <_ZN1NC1Ei>:
 80486f6:	55                   	push   %ebp
 80486f7:	89 e5                	mov    %esp,%ebp
 80486f9:	8b 45 08             	mov    0x8(%ebp),%eax
 80486fc:	c7 00 48 88 04 08    	movl   $0x8048848,(%eax)
 8048702:	8b 45 08             	mov    0x8(%ebp),%eax
 8048705:	8b 55 0c             	mov    0xc(%ebp),%edx
 8048708:	89 50 68             	mov    %edx,0x68(%eax)
 804870b:	5d                   	pop    %ebp
 804870c:	c3                   	ret    
 804870d:	90                   	nop

0804870e <_ZN1N13setAnnotationEPc>:
 804870e:	55                   	push   %ebp
 804870f:	89 e5                	mov    %esp,%ebp
 8048711:	83 ec 18             	sub    $0x18,%esp
 8048714:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048717:	89 04 24             	mov    %eax,(%esp)
 804871a:	e8 01 fe ff ff       	call   8048520 <strlen@plt>
 804871f:	8b 55 08             	mov    0x8(%ebp),%edx
 8048722:	83 c2 04             	add    $0x4,%edx
 8048725:	89 44 24 08          	mov    %eax,0x8(%esp)
 8048729:	8b 45 0c             	mov    0xc(%ebp),%eax
 804872c:	89 44 24 04          	mov    %eax,0x4(%esp)
 8048730:	89 14 24             	mov    %edx,(%esp)
 8048733:	e8 d8 fd ff ff       	call   8048510 <memcpy@plt>
 8048738:	c9                   	leave  
 8048739:	c3                   	ret    

0804873a <_ZN1NplERS_>:
 804873a:	55                   	push   %ebp
 804873b:	89 e5                	mov    %esp,%ebp
 804873d:	8b 45 08             	mov    0x8(%ebp),%eax
 8048740:	8b 50 68             	mov    0x68(%eax),%edx
 8048743:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048746:	8b 40 68             	mov    0x68(%eax),%eax
 8048749:	01 d0                	add    %edx,%eax
 804874b:	5d                   	pop    %ebp
 804874c:	c3                   	ret    
 804874d:	90                   	nop

0804874e <_ZN1NmiERS_>:
 804874e:	55                   	push   %ebp
 804874f:	89 e5                	mov    %esp,%ebp
 8048751:	8b 45 08             	mov    0x8(%ebp),%eax
 8048754:	8b 50 68             	mov    0x68(%eax),%edx
 8048757:	8b 45 0c             	mov    0xc(%ebp),%eax
 804875a:	8b 40 68             	mov    0x68(%eax),%eax
 804875d:	89 d1                	mov    %edx,%ecx
 804875f:	29 c1                	sub    %eax,%ecx
 8048761:	89 c8                	mov    %ecx,%eax
 8048763:	5d                   	pop    %ebp
 8048764:	c3                   	ret    
 8048765:	90                   	nop
 8048766:	90                   	nop
 8048767:	90                   	nop
 8048768:	90                   	nop
 8048769:	90                   	nop
 804876a:	90                   	nop
 804876b:	90                   	nop
 804876c:	90                   	nop
 804876d:	90                   	nop
 804876e:	90                   	nop
 804876f:	90                   	nop

08048770 <__libc_csu_init>:
 8048770:	55                   	push   %ebp
 8048771:	57                   	push   %edi
 8048772:	56                   	push   %esi
 8048773:	53                   	push   %ebx
 8048774:	e8 69 00 00 00       	call   80487e2 <__i686.get_pc_thunk.bx>
 8048779:	81 c3 cb 13 00 00    	add    $0x13cb,%ebx
 804877f:	83 ec 1c             	sub    $0x1c,%esp
 8048782:	8b 6c 24 30          	mov    0x30(%esp),%ebp
 8048786:	8d bb 08 ff ff ff    	lea    -0xf8(%ebx),%edi
 804878c:	e8 d3 fc ff ff       	call   8048464 <_init>
 8048791:	8d 83 04 ff ff ff    	lea    -0xfc(%ebx),%eax
 8048797:	29 c7                	sub    %eax,%edi
 8048799:	c1 ff 02             	sar    $0x2,%edi
 804879c:	85 ff                	test   %edi,%edi
 804879e:	74 29                	je     80487c9 <__libc_csu_init+0x59>
 80487a0:	31 f6                	xor    %esi,%esi
 80487a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 80487a8:	8b 44 24 38          	mov    0x38(%esp),%eax
 80487ac:	89 2c 24             	mov    %ebp,(%esp)
 80487af:	89 44 24 08          	mov    %eax,0x8(%esp)
 80487b3:	8b 44 24 34          	mov    0x34(%esp),%eax
 80487b7:	89 44 24 04          	mov    %eax,0x4(%esp)
 80487bb:	ff 94 b3 04 ff ff ff 	call   *-0xfc(%ebx,%esi,4)
 80487c2:	83 c6 01             	add    $0x1,%esi
 80487c5:	39 fe                	cmp    %edi,%esi
 80487c7:	75 df                	jne    80487a8 <__libc_csu_init+0x38>
 80487c9:	83 c4 1c             	add    $0x1c,%esp
 80487cc:	5b                   	pop    %ebx
 80487cd:	5e                   	pop    %esi
 80487ce:	5f                   	pop    %edi
 80487cf:	5d                   	pop    %ebp
 80487d0:	c3                   	ret    
 80487d1:	eb 0d                	jmp    80487e0 <__libc_csu_fini>
 80487d3:	90                   	nop
 80487d4:	90                   	nop
 80487d5:	90                   	nop
 80487d6:	90                   	nop
 80487d7:	90                   	nop
 80487d8:	90                   	nop
 80487d9:	90                   	nop
 80487da:	90                   	nop
 80487db:	90                   	nop
 80487dc:	90                   	nop
 80487dd:	90                   	nop
 80487de:	90                   	nop
 80487df:	90                   	nop

080487e0 <__libc_csu_fini>:
 80487e0:	f3 c3                	repz ret 

080487e2 <__i686.get_pc_thunk.bx>:
 80487e2:	8b 1c 24             	mov    (%esp),%ebx
 80487e5:	c3                   	ret    
 80487e6:	90                   	nop
 80487e7:	90                   	nop
 80487e8:	90                   	nop
 80487e9:	90                   	nop
 80487ea:	90                   	nop
 80487eb:	90                   	nop
 80487ec:	90                   	nop
 80487ed:	90                   	nop
 80487ee:	90                   	nop
 80487ef:	90                   	nop

080487f0 <__do_global_ctors_aux>:
 80487f0:	55                   	push   %ebp
 80487f1:	89 e5                	mov    %esp,%ebp
 80487f3:	53                   	push   %ebx
 80487f4:	83 ec 04             	sub    $0x4,%esp
 80487f7:	a1 4c 9a 04 08       	mov    0x8049a4c,%eax
 80487fc:	83 f8 ff             	cmp    $0xffffffff,%eax
 80487ff:	74 13                	je     8048814 <__do_global_ctors_aux+0x24>
 8048801:	bb 4c 9a 04 08       	mov    $0x8049a4c,%ebx
 8048806:	66 90                	xchg   %ax,%ax
 8048808:	83 eb 04             	sub    $0x4,%ebx
 804880b:	ff d0                	call   *%eax
 804880d:	8b 03                	mov    (%ebx),%eax
 804880f:	83 f8 ff             	cmp    $0xffffffff,%eax
 8048812:	75 f4                	jne    8048808 <__do_global_ctors_aux+0x18>
 8048814:	83 c4 04             	add    $0x4,%esp
 8048817:	5b                   	pop    %ebx
 8048818:	5d                   	pop    %ebp
 8048819:	c3                   	ret    
 804881a:	90                   	nop
 804881b:	90                   	nop
