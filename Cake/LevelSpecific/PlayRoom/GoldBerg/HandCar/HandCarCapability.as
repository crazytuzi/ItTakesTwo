// import Cake.LevelSpecific.PlayRoom.GoldBerg.HandCar.HandCarActor;
// import Peanuts.Animation.Features.LocomotionFeatureToyCart;
// import Cake.LevelSpecific.PlayRoom.GoldBerg.HandCar.OnHandCarComponent;

// UCLASS(Abstract)
// class UHandCarCapability : UHazeCapability
// {
// default TickGroup = ECapabilityTickGroups::GamePlay;

// 	AHazePlayerCharacter Player;

//     UHazeBaseMovementComponent Movement;

//     AHandCarActor CurrentHandCar;

// 	UHazeTriggerComponent Interaction;

// 	UOnHandCarComponent OnHandCarComponent;

// 	UPROPERTY(Category = "Animation")
// 	UAnimSequence CodyIdleAnimation;
// 	UPROPERTY(Category = "Animation")
// 	UAnimSequence MayIdleAnimation;

// 	UPROPERTY()
// 	ULocomotionFeatureToyCart CodyFeature;
// 	UPROPERTY()
// 	ULocomotionFeatureToyCart MayFeature;

// 	UPROPERTY()
// 	TSubclassOf<UHazeInputButton> HandCarInputWidgetClass;

// 	UPROPERTY()
// 	TSubclassOf<UHazeInputButton> HandCarFaultWidgetClass;

// 	UHazeInputButton HandCarPushWidget = nullptr;
// 	UHazeInputButton HandCarFaultWidget = nullptr;
	
// 	bool bLeftWindowWidgetIsActive;
// 	bool bRightWindowWidgetIsActive;
// 	//bool bStartWidgetIsActive;
// 	bool bFaultWidgetIsActive;
// 	AHazePlayerCharacter PlayerWhoOwnsPushWidget;
// 	AHazePlayerCharacter PlayerWhoOwnsFaultWidget;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
//         Movement = UHazeBaseMovementComponent::GetOrCreate(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
//         if(IsActioning(n"UsingHandCar"))
//             return EHazeNetworkActivation::ActivateLocal;
//         else
//             return EHazeNetworkActivation::DontActivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
//         if(IsActioning(ActionNames::Cancel) && !CurrentHandCar.InBossFight)
// 		    return EHazeNetworkDeactivation::DeactivateFromControl;
//         else
//             return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
//         CurrentHandCar = Cast<AHandCarActor>(GetAttributeObject(n"HandCar"));
// 		Interaction = Cast<UHazeTriggerComponent>(GetAttributeObject(n"Interaction"));

// 		OnHandCarComponent = UOnHandCarComponent::GetOrCreate(Owner);
// 		OnHandCarComponent.HandCar = CurrentHandCar;

//         Player.BlockCapabilities(n"Movement", this);
// 		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);

// 		if(CurrentHandCar.CheckIfIsPlayerAtRightHandle(Player))
// 		{
// 			Player.AttachToComponent(CurrentHandCar.Base, AttachmentRule = EAttachmentRule::KeepWorld);
// 			Player.SetActorLocation(CurrentHandCar.RightSpotAttachPoint.WorldLocation);
// 			Player.SetActorRotation(CurrentHandCar.RightSpotAttachPoint.WorldRotation);
// 		}
// 		else
// 		{
// 			Player.AttachToComponent(CurrentHandCar.Base, AttachmentRule = EAttachmentRule::KeepWorld);
// 			Player.SetActorLocation(CurrentHandCar.LeftSpotAttachPoint.WorldLocation);
// 			Player.SetActorRotation(CurrentHandCar.LeftSpotAttachPoint.WorldRotation);
// 		}

// 		if(Player.IsCody())
// 		{
// 			Player.AddLocomotionFeature(CodyFeature);
// 		}
// 		else
// 		{
// 			Player.AddLocomotionFeature(MayFeature);			
// 		}
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
//         Player.UnblockCapabilities(n"Movement", this);
// 		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
//         Player.StopAnimation();
//         Player.SetCapabilityActionState(n"UsingHandCar", EHazeActionState::Inactive);
//         Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
//         CurrentHandCar.ReleaseHandCar(Interaction, Player);

// 		OnHandCarComponent.HandCar = nullptr;

// 		if(bFaultWidgetIsActive || bRightWindowWidgetIsActive || bLeftWindowWidgetIsActive)
// 		{
// 			RemoveAllWidgets();
// 		}		

// 		//delete comp
// 	}
	
// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
//         CurrentHandCar.SetPumpInputForPlayer(IsActioning(ActionNames::TEMPLeftFaceButton), Player);

// 		FHazeRequestLocomotionData RequestData;
// 		RequestData.AnimationTag = FeatureName::ToyCart;
// 		Player.RequestLocomotion(RequestData);
	
// 		UpdateHandCarWidget();

// 		// if(Player.IsCody())
// 		// {
// 		// 	if(IsActioning(ActionNames::TEMPLeftFaceButton))
// 		// 	{
// 		// 		CurrentHandCar.CodyStarted = true;
// 		// 		CurrentHandCar.CodyPumped = true;
// 		// 	}
// 		// 	else
// 		// 	{
// 		// 		CurrentHandCar.CodyStarted = false;	
// 		// 		CurrentHandCar.CodyPumped = false;			
// 		// 	}
// 		// }
// 		// else
// 		// {
// 		// 	if(IsActioning(ActionNames::TEMPLeftFaceButton))
// 		// 	{
// 		// 		CurrentHandCar.MayStarted = true;
// 		// 		CurrentHandCar.MayPumped = true;
// 		// 	}
// 		// 	else
// 		// 	{
// 		// 		CurrentHandCar.MayStarted = false;	
// 		// 		CurrentHandCar.MayPumped = false;			
// 		// 	}
// 		// }
		
// 	}


// 	void UpdateHandCarWidget()
// 	{
// 		if (!HandCarInputWidgetClass.IsValid() || !HandCarFaultWidgetClass.IsValid())
// 			return;

// 		if((CurrentHandCar.BothPlayersAreInHandCar && CurrentHandCar.PlayerWithFullscreen != Player))
// 		{
// 			if(bFaultWidgetIsActive || bRightWindowWidgetIsActive || bLeftWindowWidgetIsActive)
// 			{
// 				RemoveAllWidgets();
// 			}
// 			return;
// 		}
// 		else
// 		{
// 			if(CurrentHandCar.Stopped)
// 			{
// 				if(bFaultWidgetIsActive || bRightWindowWidgetIsActive || bLeftWindowWidgetIsActive)
// 				{
// 					RemoveAllWidgets();
// 				}
// 				return;				
// 			}

			
// 			if(CurrentHandCar.BothPlayersAreInHandCar)
// 			{
// 				if(CurrentHandCar.PumpWindow || CurrentHandCar.CurrentPumpPosition == EPumpPosition::Middle)
// 				{
// 					if(!bRightWindowWidgetIsActive && !bLeftWindowWidgetIsActive)
// 					{
// 						if(CurrentHandCar.CheckIfIsPlayerAtRightHandle(Player))
// 						{
// 							AddPushWidget(Player, CurrentHandCar.LeftUIAttachPoint);
// 							bLeftWindowWidgetIsActive = true;	
// 						}
// 						else
// 						{
// 							AddPushWidget(Player, CurrentHandCar.RightUIAttachPoint);
// 							bRightWindowWidgetIsActive = true;
// 						}
						
// 					}

// 					if(CurrentHandCar.CurrentPumpPosition == EPumpPosition::LeftDown && !bRightWindowWidgetIsActive)
// 					{
// 						if(bLeftWindowWidgetIsActive)
// 							RemovePushWidget();

// 						AddPushWidget(Player, CurrentHandCar.RightUIAttachPoint);
// 						bRightWindowWidgetIsActive = true;			
								
// 					}
// 					else if(CurrentHandCar.CurrentPumpPosition == EPumpPosition::RightDown && !bLeftWindowWidgetIsActive)
// 					{
// 						if(bRightWindowWidgetIsActive)
// 							RemovePushWidget();

// 						AddPushWidget(Player, CurrentHandCar.LeftUIAttachPoint);
// 						bLeftWindowWidgetIsActive = true;			
// 					}
// 				}
// 				else
// 				{
// 					if(bRightWindowWidgetIsActive || bLeftWindowWidgetIsActive)
// 					{
// 						RemovePushWidget();
// 					}
// 				}
				
// 				if(CurrentHandCar.Interrupted && !bFaultWidgetIsActive)
// 					{
// 						if(CurrentHandCar.CheckIfIsPlayerAtRightHandle(CurrentHandCar.InterruptingPlayer))
// 						{
// 							AddFaultWidget(Player, CurrentHandCar.RightUIAttachPoint);						
// 						}
// 						else
// 						{
// 							AddFaultWidget(Player, CurrentHandCar.LeftUIAttachPoint);
// 						}

// 						bFaultWidgetIsActive = true;					
// 					}
					
// 					else if(!CurrentHandCar.Interrupted && bFaultWidgetIsActive)
// 					{
// 						RemoveFaultWidget();
// 						bFaultWidgetIsActive = false;
// 					}
// 			}

// 			else if(!CurrentHandCar.BothPlayersAreInHandCar)
// 			{
// 				if(CurrentHandCar.PumpDoneMoving)
// 				{
// 					if(CurrentHandCar.CheckIfIsPlayerAtRightHandle(Player))
// 					{
// 						if((CurrentHandCar.CurrentPumpPosition == EPumpPosition::LeftDown || CurrentHandCar.CurrentPumpPosition == EPumpPosition::Middle) && !bRightWindowWidgetIsActive)
// 						{
// 							if(bLeftWindowWidgetIsActive)
// 								RemovePushWidget();

// 							AddPushWidget(Player, CurrentHandCar.RightUIAttachPoint);
// 							bRightWindowWidgetIsActive = true;			
									
// 						}
// 						else if(bLeftWindowWidgetIsActive)
// 						{
// 							RemovePushWidget();
// 						}
// 					}
// 					else
// 					{
// 						if((CurrentHandCar.CurrentPumpPosition == EPumpPosition::RightDown || CurrentHandCar.CurrentPumpPosition == EPumpPosition::Middle) && !bLeftWindowWidgetIsActive)
// 						{
// 							if(bLeftWindowWidgetIsActive)
// 								RemovePushWidget();

// 							AddPushWidget(Player, CurrentHandCar.LeftUIAttachPoint);
// 							bLeftWindowWidgetIsActive = true;			
									
// 						}
// 						else if(bRightWindowWidgetIsActive)
// 						{
// 							RemovePushWidget();
// 						}
// 					}
// 				}
// 				else
// 				{
// 					if(bRightWindowWidgetIsActive || bLeftWindowWidgetIsActive)
// 					{
// 						RemovePushWidget();
// 					}
// 				}
// 			}

// 			// else if(CurrentHandCar.PumpDoneMoving)
// 			// {
// 			// 	if(!bStartWidgetIsActive)
// 			// 	{
// 			// 		if(bRightWindowWidgetIsActive || bLeftWindowWidgetIsActive)
// 			// 			RemoveWidget();

// 			// 		if(CurrentHandCar.BothPlayersAreInHandCar && CurrentHandCar.PlayerWithFullscreen == Player)
// 			// 			AddWidget(CurrentHandCar.PlayerWithFullscreen, CurrentHandCar.MiddleUIAttachPoint);
// 			// 		else
// 			// 			AddWidget(Player, CurrentHandCar.MiddleUIAttachPoint);

// 			// 		bStartWidgetIsActive = true;
// 			// 	}
// 			// }

// 			// if(bRightWindowWidgetIsActive || bLeftWindowWidgetIsActive)
// 			// 	RemoveWidget();
			
// 		}

// 	}

// 	void AddPushWidget(AHazePlayerCharacter PlayerWithWidget, UStaticMeshComponent Component)
// 	{
// 		if (HandCarPushWidget == nullptr)
// 		{
// 			HandCarPushWidget = Cast<UHazeInputButton>(PlayerWithWidget.AddWidget(HandCarInputWidgetClass));
// 			HandCarPushWidget.SetBindingName(ActionNames::TEMPLeftFaceButton);
// 			PlayerWhoOwnsPushWidget = PlayerWithWidget;					
// 		}

// 		HandCarPushWidget.AttachWidgetToComponent(Component);
// 	}

// 	void RemovePushWidget()
// 	{
// 		PlayerWhoOwnsPushWidget.RemoveWidget(HandCarPushWidget);
// 		PlayerWhoOwnsPushWidget = nullptr;
// 		HandCarPushWidget = nullptr;
// 		bRightWindowWidgetIsActive = false;
// 		bLeftWindowWidgetIsActive = false;	
// 	}

// 	void AddFaultWidget(AHazePlayerCharacter PlayerWithWidget, UStaticMeshComponent Component)
// 	{
// 		if (HandCarFaultWidget == nullptr)
// 		{
// 			HandCarFaultWidget = Cast<UHazeInputButton>(PlayerWithWidget.AddWidget(HandCarFaultWidgetClass));
// 			PlayerWhoOwnsFaultWidget = PlayerWithWidget;		
// 		}
// 		HandCarFaultWidget.AttachWidgetToComponent(Component);
// 	}

// 	void RemoveFaultWidget()
// 	{
// 		PlayerWhoOwnsFaultWidget.RemoveWidget(HandCarFaultWidget);
// 		PlayerWhoOwnsFaultWidget = nullptr;
// 		HandCarFaultWidget = nullptr;
// 		bFaultWidgetIsActive = false;
// 	}

// 	void RemoveAllWidgets()
// 	{
// 		if(HandCarPushWidget != nullptr)
// 		{
// 			PlayerWhoOwnsPushWidget.RemoveWidget(HandCarPushWidget);
// 			PlayerWhoOwnsPushWidget = nullptr;		
// 			HandCarPushWidget = nullptr;
// 			bRightWindowWidgetIsActive = false;
// 			bLeftWindowWidgetIsActive = false;	
// 		}

// 		if(HandCarFaultWidget != nullptr)
// 		{
// 			PlayerWhoOwnsFaultWidget.RemoveWidget(HandCarFaultWidget);
// 			PlayerWhoOwnsFaultWidget = nullptr;		
// 			HandCarFaultWidget = nullptr;
// 			bFaultWidgetIsActive = false;
// 		}


// 	}
// }