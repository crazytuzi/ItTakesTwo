import Vino.Time.ActorTimeDilationStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Camera.Components.WorldCameraShakeComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

UCLASS(Abstract)
class ADanglingPlanet : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent PlanetAttachment;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBillboardComponent Billboard;

    UPROPERTY(DefaultComponent, Attach = PlanetAttachment)
    USceneComponent PlanetRoot;
    default PlanetRoot.RelativeLocation = FVector(0.f, 0.f, -3000.f);

    UPROPERTY(DefaultComponent, Attach = PlanetRoot)
    UStaticMeshComponent PlanetMesh;
    
    UPROPERTY(DefaultComponent, Attach = PlanetRoot)
    UInteractionComponent InteractionPoint;

    UPROPERTY(DefaultComponent, Attach = PlanetRoot)
    UArrowComponent HitDirectionArrow;
    default HitDirectionArrow.ArrowSize = 10.f;

	UPROPERTY(DefaultComponent, Attach = PlanetMesh)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent, Attach = PlanetMesh)
	UWorldCameraShakeComponent CamShakeComp;

	UPROPERTY(DefaultComponent, Attach = PlanetMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitSuccessAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitWrongSizeAudioEvent;

	UPROPERTY(Category = "Audio Events")	
	UAkAudioEvent StopSwingingAudioEvent;

	UPROPERTY(Category = "Audio Events")	
	UAkAudioEvent LandOnPlanetAudioEvent;

	UPROPERTY(Category = "Audio Events")	
	UAkAudioEvent LeavePlanetAudioEvent;

    UPROPERTY(NotVisible)
    UAnimSequence CurrentAnimation;

    UPROPERTY(NotVisible)
    float MaxRot = 30.f;

    UPROPERTY(NotVisible)
    float InteractionVerticalOffset = 400.f;

    UPROPERTY(NotVisible)
    float MaxInteractionHorizontalOffset = 300.f;

    UPROPERTY(NotVisible)
    float HorizontalInteractionDistance = 313.f;

	FHazeConstrainedPhysicsValue SwingPhysValue;
	default SwingPhysValue.LowerBound = -4.f;
	default SwingPhysValue.UpperBound = 40.f;
	default SwingPhysValue.LowerBounciness = 0.85f;
	default SwingPhysValue.UpperBounciness = 0.2f;
	default SwingPhysValue.Friction = 2.3f;

	float LastSwingValue = 0.f;
	float SpringSpeed = 0.f;

	FHazeConstrainedPhysicsValue BouncePhysValue;
	default BouncePhysValue.LowerBound = -150.f;
	default BouncePhysValue.UpperBound = 0.f;
	default BouncePhysValue.LowerBounciness = 0.65f;
	default BouncePhysValue.UpperBounciness = 0.4f;
	default BouncePhysValue.Friction = 1.2f;

	float LastBounceValue = 0.f;

    AHazePlayerCharacter InteractingPlayer;

    FVector DirectionToPlayer;
    FVector HitDirection;

    UPROPERTY(Category = "Preview")
    bool bPreviewMaximum = false;

    UPROPERTY(Category = "Preview", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
    float PreviewFraction = 0.f;

    FHazeAnimNotifyDelegate AnimNotifyDelegate;

    UPROPERTY(NotVisible)
    ECharacterSize CurrentCharacterSize = ECharacterSize::Medium;

    UPROPERTY()
    UCurveFloat TimeDilationCurve;

	UPROPERTY()
	bool bPlaySmallAnimationWhenMedium = false;

    TArray<AActor> ActorsToIgnore;

    UPROPERTY(EditDefaultsOnly)
    FSizeBasedAnimations SizeBasedAnimations;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	bool bCollided = false;

	float LastVelocityDelta;
	float Timer = 0.f;

	bool bHasChangedDirection;
	bool bSwingingForward;
	FHazeAudioEventInstance LoopingEventInstance;

	FVector HitDir;

	bool bHit = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentAnimation = SizeBasedAnimations.Medium;
		if (bPlaySmallAnimationWhenMedium)
			CurrentAnimation = SizeBasedAnimations.Small;

		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		InteractionPoint.SetExclusiveForPlayer(EHazePlayer::Cody);

        InteractingPlayer = Game::GetCody();
        
        ActorsToIgnore.Add(Game::GetCody());
        ActorsToIgnore.Add(Game::GetMay());

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlanet");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlanet");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (bPreviewMaximum)
        {
            MaxRot = 35.f;
            HitDirectionArrow.SetWorldRotation(FRotator(0.f, 360.f * PreviewFraction, 0.f));
            FVector PreviewDirection = HitDirectionArrow.WorldRotation.Vector();

            FRotator PreviewTargetRotation = FRotator(PreviewDirection.Y * MaxRot * 1.31f, PlanetAttachment.WorldRotation.Yaw, PreviewDirection.X * MaxRot * 1.31f);

            PlanetAttachment.SetWorldRotation(PreviewTargetRotation);
        }
        else
        {
            MaxRot = 5.f;
            PlanetAttachment.SetRelativeRotation(FRotator(0.f, 90.f, 0.f));
            HitDirectionArrow.SetRelativeRotation(FRotator::ZeroRotator);
        }

		LastVelocityDelta = PlanetRoot.GetWorldLocation().Size();
    }

	UFUNCTION(CallInEditor)
	void UpdatePlanetHeight()
	{
		FHitResult HitResult;
		System::LineTraceSingle(ActorLocation, ActorLocation - FVector(0.f, 0.f, 5000), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::ForDuration, HitResult, true);

		if (HitResult.bBlockingHit)
		{
			FVector NewLoc = FVector(ActorLocation.X, ActorLocation.Y, HitResult.ImpactPoint.Z + 3600.f);
			SetActorLocation(NewLoc);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlanet(AHazePlayerCharacter Player, FHitResult Hit)
	{
		BouncePhysValue.AddImpulse(-350.f);
		HazeAkComp.HazePostEvent(LandOnPlanetAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlanet(AHazePlayerCharacter Player)
	{
		BouncePhysValue.AddImpulse(-220.f);
		HazeAkComp.HazePostEvent(LeavePlanetAudioEvent);
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (InteractingPlayer == nullptr)
			return;

        FVector Loc = InteractingPlayer.ActorLocation - PlanetMesh.WorldLocation;
        DirectionToPlayer = Math::ConstrainVectorToPlane(Loc, FVector::UpVector);
        DirectionToPlayer = DirectionToPlayer.GetSafeNormal();
        HitDirection = -DirectionToPlayer;

        HitDirectionArrow.SetWorldRotation(HitDirection.Rotation());
        FVector InteractionLoc = FVector(PlanetMesh.WorldLocation.X, PlanetMesh.WorldLocation.Y, PlanetMesh.WorldLocation.Z - InteractionVerticalOffset);
        InteractionPoint.SetWorldLocation(InteractionLoc + DirectionToPlayer * MaxInteractionHorizontalOffset);

		float VelocityDelta = PlanetRoot.GetWorldLocation().Size() - LastVelocityDelta;
		LastVelocityDelta = PlanetRoot.GetWorldLocation().Size();
		
		float NormalizedVelocityDelta = HazeAudio::NormalizeRTPC01(FMath::Abs(VelocityDelta), 0.f, 7.f);
		HazeAkComp.SetRTPCValue("Rtpc_SpaceStation_Platform_DanglingPlanet_Velocity", NormalizedVelocityDelta);

		// if(HazeAkComp.HazeIsEventActive(LoopingEventInstance.EventID))
		// {			
		// 	if(VelocityDelta > 0)
		// 	{
		// 		if(!bSwingingForward)
		// 		{
		// 			bHasChangedDirection = true;
		// 			PlaySwingForwardSound();
		// 		}
		// 		bSwingingForward = true;				
		// 	}
		// 	else if(VelocityDelta < 0)
		// 	{
		// 		if(bSwingingForward)
		// 		{
		// 			bHasChangedDirection = true;
		// 			PlaySwingBackwardSound();
		// 		}
		// 		bSwingingForward = false;				
		// 	}

		// 	if(NormalizedVelocityDelta == 0)
		// 	{				
		// 		Timer += DeltaTime;
		// 		if(Timer > 0.5f)
		// 		{
		// 			HazeAkComp.HazeStopEvent(LoopingEventInstance.PlayingID, 1500.f, EAkCurveInterpolation::Log1, true);
		// 			Timer = 0.f;
		// 		}
		// 	}
		// }

		if (bHit)
		{
			FHitResult HitResult;
			System::SphereTraceSingle(PlanetMesh.WorldLocation, PlanetMesh.WorldLocation + FVector(0.f, 0.f, 0.1f), 500.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true, FLinearColor::Green, FLinearColor::Red, 1.f);

			if (HitResult.bBlockingHit && !bCollided)
			{
				bCollided = true;
				SwingPhysValue.AddImpulse(-100.f);
				SpringSpeed = 10.f;
			}

			SpringSpeed = FMath::FInterpConstantTo(SpringSpeed, 10.f, DeltaTime, 3.5f);
			SwingPhysValue.SpringTowards(0.f, SpringSpeed);
			SwingPhysValue.Update(DeltaTime);

			FRotator TargetRotation = FRotator(HitDir.Y * SwingPhysValue.Value, PlanetAttachment.WorldRotation.Yaw, HitDir.X * SwingPhysValue.Value);
			PlanetAttachment.SetWorldRotation(TargetRotation);

			if (FMath::IsNearlyEqual(LastSwingValue, SwingPhysValue.Value, 0.025f) && FMath::IsNearlyEqual(LastSwingValue, 0.f, 0.025f))
			{
				bHit = false;
				InteractionPoint.Enable(n"Swinging");
				HazeAkComp.HazePostEvent(StopSwingingAudioEvent);
			}

			LastSwingValue = SwingPhysValue.Value;
		}

		BouncePhysValue.SpringTowards(0.f, 50.f);
		BouncePhysValue.Update(DeltaTime);

		if (LastBounceValue != BouncePhysValue.Value)
		{
			PlanetAttachment.SetRelativeLocation(FVector(0.f, 0.f, BouncePhysValue.Value));
			LastBounceValue = BouncePhysValue.Value;
		}
    }

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		if (Player.HasControl())
		{
			FVector PlayerLoc = PlanetMesh.WorldLocation + (DirectionToPlayer * HorizontalInteractionDistance);
			TArray<AActor> DownActorsToIgnore;
			DownActorsToIgnore.Add(Game::GetCody());
			DownActorsToIgnore.Add(Game::GetMay());
			FHitResult Hit;
			System::LineTraceSingle(PlayerLoc, PlayerLoc - (FVector(0.f, 0.f, 5000.f)), ETraceTypeQuery::Visibility, false, DownActorsToIgnore, EDrawDebugTrace::None, Hit, true);

			PlayerLoc.Z = Hit.ImpactPoint.Z;

			if (CurrentCharacterSize == ECharacterSize::Small || (CurrentCharacterSize == ECharacterSize::Medium && bPlaySmallAnimationWhenMedium))
				PlayerLoc = Player.ActorLocation;

			NetPlanetHit(Player, PlayerLoc, HitDirection.Rotation());
		}
    }

	UFUNCTION(NetFunction)
	void NetPlanetHit(AHazePlayerCharacter Player, FVector Loc, FRotator Rot)
	{
        Player.PlayEventAnimation(Animation = CurrentAnimation);
        Player.SmoothSetLocationAndRotation(Loc, Rot);

		if (CurrentCharacterSize == ECharacterSize::Small || (CurrentCharacterSize == ECharacterSize::Medium && bPlaySmallAnimationWhenMedium))
		{
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationStrainingEffort");
			return;
		}

		InteractionPoint.Disable(n"Swinging");
		bCollided = false;

        AnimNotifyDelegate.BindUFunction(this, n"OnPlanetHit");
        Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
	}

    UFUNCTION()
    void OnPlanetHit(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
    {
        Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		SpringSpeed = 0.f;
		HitDir = HitDirection;

		if (CurrentCharacterSize == ECharacterSize::Medium)
		{
			SwingPhysValue.AddImpulse(15.f);
			HazeAkComp.HazePostEvent(HitWrongSizeAudioEvent);
		}
		else
		{
			SwingPhysValue.AddImpulse(120.f);
			ForceFeedbackComp.Play();
			CamShakeComp.Play();
			HazeAkComp.HazePostEvent(HitSuccessAudioEvent);
		}

		bHit = true;

		// if(StartSwingingLoopEvent != nullptr)
		// {
		// 	LoopingEventInstance = HazeAkComp.HazePostEvent(StartSwingingLoopEvent);
		// 	bHasChangedDirection = true;
		// }
    }

	// void PlaySwingForwardSound()
	// {
	// 	if(bHasChangedDirection && SwingForwardEvent != nullptr)
	// 	{
	// 		HazeAkComp.HazePostEvent(SwingForwardEvent);
	// 		bHasChangedDirection = false;
	// 	}
	// }

	// void PlaySwingBackwardSound()
	// {
	// 	if(bHasChangedDirection && SwingBackwardEvent != nullptr)
	// 	{
	// 		HazeAkComp.HazePostEvent(SwingBackwardEvent);
	// 		bHasChangedDirection = false;
	// 	}
	// }
}