import Vino.Interactions.InteractionComponent;
import Vino.Interactions.OneShotInteraction;
event void FOnDisableCarousel();

event void FOnMayJumpedOnHorse();
event void FOnCodyJumpedOnHorse();
event void FOnMayStayedOnHorseLong();
event void FOnCodyStayedOnHorseLong();

class AMiniCarosuel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent BaseRotatingRoot;
	UPROPERTY(DefaultComponent, Attach = BaseRotatingRoot)	
	USceneComponent HorsePairOne;
	UPROPERTY(DefaultComponent, Attach = BaseRotatingRoot)	
	USceneComponent HorsePairTwo;
	UPROPERTY(DefaultComponent, Attach = BaseRotatingRoot)	
	USceneComponent HorsePairThree;

	UPROPERTY(DefaultComponent, Attach = BaseRotatingRoot)	
	UStaticMeshComponent RotatingMesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent BottomMesh;

	UPROPERTY(DefaultComponent, Attach = HorsePairOne)	
	UHazeSkeletalMeshComponentBase HorseOne;
	UPROPERTY(DefaultComponent, Attach = HorsePairOne)	
	UHazeSkeletalMeshComponentBase HorseTwo;

	UPROPERTY(DefaultComponent, Attach = HorsePairTwo)	
	UHazeSkeletalMeshComponentBase HorseThree;
	UPROPERTY(DefaultComponent, Attach = HorsePairTwo)	
	UHazeSkeletalMeshComponentBase HorseFour;

	UPROPERTY(DefaultComponent, Attach = HorsePairThree)	
	UHazeSkeletalMeshComponentBase HorseFive;
	UPROPERTY(DefaultComponent, Attach = HorsePairThree)	
	UHazeSkeletalMeshComponentBase HorseSix;

	UPROPERTY(DefaultComponent, Attach = HorseOne)
	UInteractionComponent HorseInteractionOne;
	UPROPERTY(DefaultComponent, Attach = HorseTwo)
	UInteractionComponent HorseInteractionTwo;
	UPROPERTY(DefaultComponent, Attach = HorseThree)
	UInteractionComponent HorseInteractionThree;
	UPROPERTY(DefaultComponent, Attach = HorseFour)
	UInteractionComponent HorseInteractionFour;
	UPROPERTY(DefaultComponent, Attach = HorseFive)
	UInteractionComponent HorseInteractionFive;
	UPROPERTY(DefaultComponent, Attach = HorseSix)
	UInteractionComponent HorseInteractionSix;

	UPROPERTY(DefaultComponent, Attach = HorseOne)	
	USceneComponent JumpOffLocationHorseOne;
	UPROPERTY(DefaultComponent, Attach = HorseTwo)	
	USceneComponent JumpOffLocationHorseTwo;
	UPROPERTY(DefaultComponent, Attach = HorseThree)	
	USceneComponent JumpOffLocationHorseThree;
	UPROPERTY(DefaultComponent, Attach = HorseFour)	
	USceneComponent JumpOffLocationHorseFour;
	UPROPERTY(DefaultComponent, Attach = HorseFive)	
	USceneComponent JumpOffLocationHorseFive;
	UPROPERTY(DefaultComponent, Attach = HorseSix)	
	USceneComponent JumpOffLocationHorseSix;

	UPROPERTY(DefaultComponent, Attach = HorseOne)
	UHazeCameraComponent CameraHorseOne;
	UPROPERTY(DefaultComponent, Attach = HorseTwo)
	UHazeCameraComponent CameraHorseTwo;
	UPROPERTY(DefaultComponent, Attach = HorseThree)
	UHazeCameraComponent CameraHorseThree;
	UPROPERTY(DefaultComponent, Attach = HorseFour)
	UHazeCameraComponent CameraHorseFour;
	UPROPERTY(DefaultComponent, Attach = HorseFive)
	UHazeCameraComponent CameraHorseFive;
	UPROPERTY(DefaultComponent, Attach = HorseSix)
	UHazeCameraComponent CameraHorseSix;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSetting;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartCarouselAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopCarouselAudioEvent;

	float LocalGameTime;

	UPROPERTY()
	UAnimSequence CodyMH;
	UPROPERTY()
	UAnimSequence MayMH;

	UPROPERTY()
	FText CancelText;

	FHazeAcceleratedFloat PairOne;
	FHazeAcceleratedFloat PairTwo;
	FHazeAcceleratedFloat PairThree;

	UInteractionComponent MaysInteraction;
	UInteractionComponent CodysInteraction;

	FHazeAcceleratedFloat CurrentRotationSpeed;
	FHazeAcceleratedFloat CurrentHorseBounceHeight;

	UPROPERTY()
	FOnDisableCarousel OnDisableCarousel;
	UPROPERTY()
	FOnMayJumpedOnHorse OnMayJumpedOnHorse;
	UPROPERTY()
	FOnCodyJumpedOnHorse OnCodyJumpedOnHorse;
	UPROPERTY()
	FOnMayStayedOnHorseLong OnMayStayedOnHorseLong;
	UPROPERTY()
	FOnCodyStayedOnHorseLong OnCodyStayedOnHorseLong;

	UPROPERTY()
	float AutoDisableTimer = 25.f;
	float AutoDisableTimerTemp = 25.f;


	float PairTwoOffset;
	float PairThreeOffset;

	bool bMiniCarouselStarted = false;
	
	UPROPERTY()
	TSubclassOf<UHazeCapability> PlayerMiniCarouselCapability;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HorseInteractionOne.OnActivated.AddUFunction(this, n"OnInteractingHorse");
		HorseInteractionTwo.OnActivated.AddUFunction(this, n"OnInteractingHorse");
		HorseInteractionThree.OnActivated.AddUFunction(this, n"OnInteractingHorse");
		HorseInteractionFour.OnActivated.AddUFunction(this, n"OnInteractingHorse");
		HorseInteractionFive.OnActivated.AddUFunction(this, n"OnInteractingHorse");
		HorseInteractionSix.OnActivated.AddUFunction(this, n"OnInteractingHorse");

		HorseInteractionOne.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
		HorseInteractionTwo.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
		HorseInteractionThree.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
		HorseInteractionFour.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
		HorseInteractionFive.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
		HorseInteractionSix.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");

		HorseInteractionOne.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		HorseInteractionTwo.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		HorseInteractionThree.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		HorseInteractionFour.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		HorseInteractionFive.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		HorseInteractionSix.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BaseRotatingRoot.AddLocalRotation(FRotator(0, CurrentRotationSpeed.Value, 0) * DeltaSeconds);
		LocalGameTime = Time::GameTimeSeconds;

		FVector RelativeLocationOne;
		RelativeLocationOne.Z = FMath::Sin(LocalGameTime * 5.f) * CurrentHorseBounceHeight.Value;
		HorsePairOne.SetRelativeLocation(RelativeLocationOne);
		PairOne.Value = RelativeLocationOne.Z;

		FVector RelativeLocationPairTwo;
		RelativeLocationPairTwo.Z = FMath::Sin(LocalGameTime * 5.f + PairTwoOffset) * CurrentHorseBounceHeight.Value;
		HorsePairTwo.SetRelativeLocation(RelativeLocationPairTwo);
		PairTwo.Value = RelativeLocationPairTwo.Z;

		FVector RelativeLocationThree;
		RelativeLocationThree.Z = FMath::Sin(LocalGameTime * 5.f + PairThreeOffset) * CurrentHorseBounceHeight.Value;
		HorsePairThree.SetRelativeLocation(RelativeLocationThree);
		PairThree.Value = RelativeLocationThree.Z;

		HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_MiniCarousel_Speed", CurrentRotationSpeed.Value);


		if(bMiniCarouselStarted)
		{
			//PrintToScreen("AutoDisableTimerTemp " + AutoDisableTimerTemp);
			AutoDisableTimerTemp -= DeltaSeconds;
			if(AutoDisableTimerTemp <= 0)
			{
				if(HasControl())
				{
					NetToggleMiniCarosuel();
				}
			}

			CurrentRotationSpeed.SpringTo(35, 3, 1, DeltaSeconds);
			CurrentHorseBounceHeight.SpringTo(35, 3, 1, DeltaSeconds);

			PairTwoOffset = FMath::Lerp(PairTwoOffset, 5.f, 0.003f);
			PairThreeOffset = FMath::Lerp(PairThreeOffset, 10.f, 0.004f);
		}
		else
		{
			CurrentRotationSpeed.SpringTo(0, 6, 1, DeltaSeconds);
			CurrentHorseBounceHeight.SpringTo(0, 6, 1, DeltaSeconds);
			
			PairTwoOffset = FMath::Lerp(PairTwoOffset, 0.f, 0.003f);
			PairThreeOffset = FMath::Lerp(PairThreeOffset, 0.f, 0.004f);
		}
	}
	
	UFUNCTION()
	void ToggleMiniCarosuel()
	{
		if(HasControl())
		{
			NetToggleMiniCarosuel();
		}
	}

	UFUNCTION(NetFunction)
	void NetToggleMiniCarosuel()
	{
		if(bMiniCarouselStarted == false)
		{
			AutoDisableTimerTemp = AutoDisableTimer;
			bMiniCarouselStarted = true;

			HazeAkComp.HazePostEvent(StartCarouselAudioEvent);

			if(HorseInteractionOne != MaysInteraction)
				HorseInteractionOne.EnableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			if(HorseInteractionTwo != MaysInteraction)
				HorseInteractionTwo.EnableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			if(HorseInteractionThree != MaysInteraction)
				HorseInteractionThree.EnableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			if(HorseInteractionFour != MaysInteraction)	
				HorseInteractionFour.EnableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			if(HorseInteractionFive != MaysInteraction)	
				HorseInteractionFive.EnableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			if(HorseInteractionSix != MaysInteraction)	
				HorseInteractionSix.EnableForPlayer(Game::GetCody(), n"NotForThisPlayer");

			if(HorseInteractionOne != CodysInteraction)
				HorseInteractionOne.EnableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			if(HorseInteractionTwo != CodysInteraction)
				HorseInteractionTwo.EnableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			if(HorseInteractionThree != CodysInteraction)
				HorseInteractionThree.EnableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			if(HorseInteractionFour != CodysInteraction)	
				HorseInteractionFour.EnableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			if(HorseInteractionFive != CodysInteraction)	
				HorseInteractionFive.EnableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			if(HorseInteractionSix != CodysInteraction)	
				HorseInteractionSix.EnableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		}
		else if(bMiniCarouselStarted == true)
		{
			System::SetTimer(this, n"EnableInteraction", 2.f, false);
			bMiniCarouselStarted = false;

			HorseInteractionOne.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			HorseInteractionTwo.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			HorseInteractionThree.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			HorseInteractionFour.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			HorseInteractionFive.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			HorseInteractionSix.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			HorseInteractionOne.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			HorseInteractionTwo.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			HorseInteractionThree.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			HorseInteractionFour.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			HorseInteractionFive.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			HorseInteractionSix.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		}
	}
	UFUNCTION()
	void EnableInteraction()
	{
		OnDisableCarousel.Broadcast();
		HazeAkComp.HazePostEvent(StopCarouselAudioEvent);
	}

	UFUNCTION(NetFunction)
	void BroadCastMayJumpedOnHorse()
	{
		OnMayJumpedOnHorse.Broadcast();
	}
	UFUNCTION(NetFunction)
	void BroadCastCodyJumpedOnHorse()
	{
		OnCodyJumpedOnHorse.Broadcast();
	}
	UFUNCTION(NetFunction)
	void BroadCastMayStayedOnHorseLong()
	{
		OnMayStayedOnHorseLong.Broadcast();
	}
	UFUNCTION(NetFunction)
	void BroadCastCodyStayedOnHorseLong()
	{
		OnCodyStayedOnHorseLong.Broadcast();
	}


	UFUNCTION()
	void OnInteractingHorse(UInteractionComponent InteractComponent, AHazePlayerCharacter Player)
	{
		BlockAllInteractionsForPlayer(Player, InteractComponent);

		if(Player == Game::GetCody())
			Game::GetMay().DisableOutlineByInstigator(this);
		else
			Game::GetCody().DisableOutlineByInstigator(this);

		Player.AddCapability(PlayerMiniCarouselCapability);
		Player.SetCapabilityAttributeObject(n"Carousel", this);
		Player.SetCapabilityAttributeObject(n"Interaction", InteractComponent);

		if(InteractComponent == HorseInteractionOne)
		{
			Player.SetCapabilityAttributeObject(n"CameraHorse", CameraHorseOne);
			Player.SetCapabilityAttributeObject(n"JumpOffLocation", JumpOffLocationHorseOne);
		}
		if(InteractComponent == HorseInteractionTwo)
		{
			Player.SetCapabilityAttributeObject(n"CameraHorse", CameraHorseTwo);
			Player.SetCapabilityAttributeObject(n"JumpOffLocation", JumpOffLocationHorseTwo);
		}
		if(InteractComponent == HorseInteractionThree)
		{
			Player.SetCapabilityAttributeObject(n"CameraHorse", CameraHorseThree);
			Player.SetCapabilityAttributeObject(n"JumpOffLocation", JumpOffLocationHorseThree);
		}
		if(InteractComponent == HorseInteractionFour)
		{
			Player.SetCapabilityAttributeObject(n"CameraHorse", CameraHorseFour);
			Player.SetCapabilityAttributeObject(n"JumpOffLocation", JumpOffLocationHorseFour);
		}
		if(InteractComponent == HorseInteractionFive)
		{
			Player.SetCapabilityAttributeObject(n"CameraHorse", CameraHorseFive);
			Player.SetCapabilityAttributeObject(n"JumpOffLocation", JumpOffLocationHorseFive);
		}
		if(InteractComponent == HorseInteractionSix)
		{
			Player.SetCapabilityAttributeObject(n"CameraHorse", CameraHorseSix);
			Player.SetCapabilityAttributeObject(n"JumpOffLocation", JumpOffLocationHorseSix);
		}
	}

	UFUNCTION()
	void BlockAllInteractionsForPlayer(AHazePlayerCharacter Player, UInteractionComponent InteractionInstigator)
	{
		HorseInteractionOne.DisableForPlayer(Player, n"NotForThisPlayer");
		HorseInteractionTwo.DisableForPlayer(Player, n"NotForThisPlayer");
		HorseInteractionThree.DisableForPlayer(Player, n"NotForThisPlayer");
		HorseInteractionFour.DisableForPlayer(Player, n"NotForThisPlayer");
		HorseInteractionFive.DisableForPlayer(Player, n"NotForThisPlayer");
		HorseInteractionSix.DisableForPlayer(Player, n"NotForThisPlayer");

		if(Player == Game::GetCody())
		{
			InteractionInstigator.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
			CodysInteraction = InteractionInstigator;
		}
		if(Player == Game::GetMay())
		{
			InteractionInstigator.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
			MaysInteraction = InteractionInstigator;
		}
	}
	UFUNCTION()
	void UnBlockAllInteractionsForPlayer(AHazePlayerCharacter Player, UInteractionComponent InteractionInstigator)
	{
		if(Player == Game::GetCody())
		{
			CodysInteraction = nullptr;
			Game::GetMay().EnableOutlineByInstigator(this);
		}
			
		else
		{
			MaysInteraction = nullptr;
			Game::GetCody().EnableOutlineByInstigator(this);
		}
			


		if(!bMiniCarouselStarted)
			return;

		if(Player == Game::GetCody())
		{
			if(HorseInteractionOne != MaysInteraction)
				HorseInteractionOne.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionTwo != MaysInteraction)
				HorseInteractionTwo.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionThree != MaysInteraction)
				HorseInteractionThree.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionFour != MaysInteraction)	
				HorseInteractionFour.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionFive != MaysInteraction)	
				HorseInteractionFive.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionSix != MaysInteraction)	
				HorseInteractionSix.EnableForPlayer(Player, n"NotForThisPlayer");
		}
		if(Player == Game::GetMay())
		{
			if(HorseInteractionOne != CodysInteraction)
				HorseInteractionOne.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionTwo != CodysInteraction)
				HorseInteractionTwo.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionThree != CodysInteraction)
				HorseInteractionThree.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionFour != CodysInteraction)	
				HorseInteractionFour.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionFive != CodysInteraction)	
				HorseInteractionFive.EnableForPlayer(Player, n"NotForThisPlayer");
			if(HorseInteractionSix != CodysInteraction)	
				HorseInteractionSix.EnableForPlayer(Player, n"NotForThisPlayer");
		}
		
		if(Player == Game::GetCody())
		{
			InteractionInstigator.EnableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		}	
		if(Player == Game::GetMay())
		{
			InteractionInstigator.EnableForPlayer(Game::GetCody(), n"NotForThisPlayer");
		}
	}
}

