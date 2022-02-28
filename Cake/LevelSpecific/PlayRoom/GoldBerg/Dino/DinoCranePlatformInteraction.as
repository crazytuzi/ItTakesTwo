import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;
import Peanuts.Spline.SplineComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Tutorial.TutorialStatics;

event void FDinoCraneInteractionEventSignature();

class ADinoCranePlatformInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UInteractionComponent Interaction;
	default Interaction.ActivationSettings.ActivationTag = n"DinoCraneInteraction";

	default Interaction.FocusShape.Type = EHazeShapeType::None;

	default Interaction.ActionShape.Type = EHazeShapeType::Box;
	default Interaction.ActionShape.BoxExtends = FVector(1300.f, 900.f, 2000.f);
	default Interaction.ActionShapeTransform = FTransform(FVector(-500.f, 0.f, -1200.f));

	UPROPERTY(DefaultComponent, Attach = Interaction)
	UBillboardComponent Billboard;
	default Billboard.RelativeScale3D = FVector(5.f);
	default Billboard.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = Interaction)
	UArrowComponent Facing;
	default Facing.RelativeScale3D = FVector(5.f);

	UPROPERTY(Category = "Dino Events")
	FDinoCraneInteractionEventSignature StartInteracting;

	UPROPERTY(Category = "Dino Events")
	FDinoCraneInteractionEventSignature EndedInteracting;

	UPROPERTY(DefaultComponent, Attach = Interaction)
	USceneComponent DinoTargetPosition;

	UPROPERTY(DefaultComponent, Attach = Interaction)
	UHazeSplineComponent Spline;	

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncPosition;	

	/* Whether to automatically move the platform down again when released, but still stick to the spline. */
	UPROPERTY()
	float PlatformGravity = 0.f;

	/* Platform move speed when being moved by dino */
	UPROPERTY()
	float PlatformMoveSpeed = 1000;

	/* Whether to check for collision and prevent the platform from moving when it hits something. */
	UPROPERTY()
	bool bCheckMoveCollision = true;

	/* How close the dino head needs to be to interact. */
	UPROPERTY()
	float HeadInteractionDistance = 1400.f;

	/* How close the dino head needs to be to interact in Z. */
	UPROPERTY()
	float HeadInteractionVerticalDistance = 500.f;

	bool IsStopped;
	bool bHasPlayedImpactSound = false;
	bool bWaitForAwake = true;
	float AudioTimer = 0.f;

	AHazePlayerCharacter GrabbingPlayer;

	UPROPERTY(DefaultComponent, Attach = Interaction)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	bool bPlayImpactSoundOnSplineStart = false;
	
	UPROPERTY()
	bool bPlayImpactSoundOnSplineEnd = false;

	UPROPERTY()
	UAkAudioEvent OnGrabbedAudio;

	UPROPERTY()
	UAkAudioEvent OnStoppedAudio;

	UPROPERTY()
	UAkAudioEvent ImpactEvent;

	UPROPERTY()
	bool bIsHorizontal;

	bool bHasShownTutorial;
	FVector PrevPosition;	
	bool bAudioPendingStop = false;
	float LastSplinePos = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnActivated.AddUFunction(this, n"OnPlatformGrabbed");
		Spline.DetachFromParent(bMaintainWorldPosition = true);

		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"CheckDinoHeadNearby");
		Condition.bDisplayVisualsWhileDisabled = true;
		Condition.bOnlyCheckOnPlayerControl = true;
		Interaction.AddTriggerCondition(n"DinoHeadNearby", Condition);	

		SyncPosition.Value = ActorLocation;
	}

	UFUNCTION()
	bool CheckDinoHeadNearby(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		auto RidingComp = UDinoCraneRidingComponent::Get(Player);
		if (RidingComp == nullptr)
			return false;

		auto DinoCrane = RidingComp.DinoCrane;
		if (DinoCrane == nullptr)
			return false;

		FVector HeadWorldPos = DinoCrane.GetWorldPositionOfHead();
		return HeadWorldPos.Dist2D(ActorLocation) < HeadInteractionDistance && FMath::Abs(HeadWorldPos.Z - ActorLocation.Z) < HeadInteractionVerticalDistance;
	}

	UFUNCTION()
	void OnPlatformGrabbed(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		auto RidingComp = UDinoCraneRidingComponent::Get(Player);
		auto DinoCrane = RidingComp.DinoCrane;
		GrabbingPlayer = Player;
		IsStopped = false;
		DinoCrane.GrabbedPlatform = this;
		DinoCrane.MovePlatformSpeed = PlatformMoveSpeed;
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		StartInteracting.Broadcast();	
		if(OnGrabbedAudio != nullptr)
		{
			HazeAkComp.HazePostEvent(OnGrabbedAudio);	
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneVerticalMovement, 0.f);
			bAudioPendingStop = false;
		}


		ShowCancelPromptWithText(Player, this, DinoCrane.ReleaseText);
		ShowTutorial();
	}

	void ShowTutorial()
	{
		FTutorialPrompt Prompt;
		Prompt.Action = AttributeVectorNames::MovementRaw;
		Prompt.MaximumDuration = 3;
		Prompt.Mode = ETutorialPromptMode::RemoveWhenPressed;

		if (bIsHorizontal)
		{
			Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		}
		else
		{
			Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		}

		ShowTutorialPrompt(GrabbingPlayer, Prompt, this);
	}

	void StopTutorial()
	{
		RemoveTutorialPromptByInstigator(GrabbingPlayer, this);
	}

	void ReleasePlatform()
	{
		if (GrabbingPlayer == nullptr)
			return;

		auto RidingComp = UDinoCraneRidingComponent::Get(GrabbingPlayer);
		auto DinoCrane = RidingComp.DinoCrane;
		if (!DinoCrane.HasControl())
			return;

		NetReleasePlatform();

	}

	UFUNCTION(NetFunction)
	void NetReleasePlatform()
	{
		auto RidingComp = UDinoCraneRidingComponent::Get(GrabbingPlayer);
		auto DinoCrane = RidingComp.DinoCrane;

		if (DinoCrane != nullptr)
			DinoCrane.GrabbedPlatform = nullptr;

		ForceReleasePlayerFromPlatform();
	}

	void ForceReleasePlayerFromPlatform()
	{
		if (GrabbingPlayer == nullptr)
			return;

		RemoveCancelPromptByInstigator(GrabbingPlayer, this);
		StopTutorial();
		GrabbingPlayer.UnblockCapabilities(CapabilityTags::Interaction, this);
		GrabbingPlayer = nullptr;
		EndedInteracting.Broadcast();
		bAudioPendingStop = true;		
	}

    bool IsHitBehindDirection(FHitResult Hit, FVector FromLocation, FVector ToLocation)
    {
        FVector DirectionToHit = (Hit.ImpactPoint - FromLocation).GetSafeNormal();
        FVector DirectionToMove = (ToLocation - FromLocation).GetSafeNormal();

        float Angle = DirectionToHit.AngularDistanceForNormals(DirectionToMove);
        return Angle > 0.5 * PI;
    }

	TArray<FHitResult> PrevHits;
	FVector ModifyMovementForCollision(FVector PrevPosition, FVector NewPosition, bool& OutIsOverlapping, bool bIgnoreOverlaps = false)
	{
		if (!bCheckMoveCollision)
			return NewPosition;
		if (PrevPosition == NewPosition && bIgnoreOverlaps)
			return NewPosition;

		TArray<AActor> Attachments;
		GetAttachedActors(Attachments);

		FVector TargetPosition = NewPosition;

		for(auto AttachedActor : Attachments)
		{
			auto CollisionComp = Cast<UPrimitiveComponent>(AttachedActor.RootComponent);
			if (CollisionComp == nullptr)
				continue;
			if (CollisionComp.CollisionEnabled == ECollisionEnabled::NoCollision)
				continue;

			FTransform RelTransform = CollisionComp.GetWorldTransform().GetRelativeTransform(ActorTransform);
			FTransform OldTransform = RelTransform * FTransform(ActorRotation, PrevPosition);
			FTransform NewTransform;

			for (int MaxTraces = 0; MaxTraces < 10; ++MaxTraces)
			{
				NewTransform = RelTransform * FTransform(ActorRotation, TargetPosition);
				FVector Delta = NewTransform.Location - OldTransform.Location;
				float DeltaLength = Delta.Size();
				float DeltaPct = 1.f;

				if (DeltaLength <= 0.001f)
					break;

				TArray<FHitResult> Hits;
				Trace::SweepComponentForHits(CollisionComp, Delta, Hits);

				bool bHasBlock = false;
				float Penetration = 0.f;
				for(const auto& Hit : Hits)
				{
					if (Hit.Actor == this)
						continue;
					if (Cast<ADinoCrane>(Hit.Actor) != nullptr)
						continue;
					if (Hit.Component.IsAttachedTo(this))
						continue;
					if (Hit.Component.CollisionObjectType == ECollisionChannel::PlayerCharacter)
						continue;

					if (bIgnoreOverlaps && Hit.bStartPenetrating)
						continue;

					if (IsHitBehindDirection(Hit, OldTransform.Location, NewTransform.Location))
						continue;

					if (Hit.bBlockingHit)
					{
						if (Hit.bStartPenetrating)
						{
							OutIsOverlapping = true;							
						}
						else
						{
							bHasBlock = true;
							float WantPct = Hit.Time - (0.1f / DeltaLength);
							if (WantPct < DeltaPct)
								DeltaPct = WantPct;
						}
					}
				}

				PrevHits = Hits;

				if (!bHasBlock)
					break;

				if (DeltaPct <= 0.01f || OutIsOverlapping)
				{
					TargetPosition = PrevPosition;
					break;
				}

				TargetPosition = PrevPosition + (TargetPosition - PrevPosition) * DeltaPct;

				float TargDist = TargetPosition.Distance(PrevPosition);
				float DeltaDist = DeltaLength * DeltaPct;
				ensure(FMath::IsNearlyEqual(TargDist, DeltaDist, 0.1f));
			}
		}

		return TargetPosition;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bWaitForAwake)
		{
			AudioTimer += DeltaTime;

			if(AudioTimer >= 1.f)
			{
				bWaitForAwake = false;
			}
		}

		if (GrabbingPlayer != nullptr)
		{
			auto RidingComp = UDinoCraneRidingComponent::Get(GrabbingPlayer);
			auto DinoCrane = RidingComp.DinoCrane;
			if (DinoCrane == nullptr)
			{
				ForceReleasePlayerFromPlatform();
			}
		}

		if (HasControl())
			SyncPosition.Value = ActorLocation;

		if (PlatformGravity != 0.f && GrabbingPlayer == nullptr && HasControl())
		{
			FVector WantPosition = ActorLocation + FVector(0.f, 0.f, -1.f * DeltaTime * PlatformGravity);
			FVector NewPosition = Spline.FindLocationClosestToWorldLocation(WantPosition, ESplineCoordinateSpace::World);

			bool bIsOverlapping = false;
			NewPosition = ModifyMovementForCollision(ActorLocation, NewPosition, bIsOverlapping, bIgnoreOverlaps = true);
			if (!NewPosition.Equals(ActorLocation, 0.01f))
				ActorLocation = NewPosition;
		}

		if (!HasControl() && GrabbingPlayer == nullptr)
		{
			ActorLocation = SyncPosition.Value;
		}

		FVector CurPlatformPos = ActorLocation;
		float SplineDist = 0.f;
		FVector ClosestSplinePos;
		Spline.FindDistanceAlongSplineAtWorldLocation(CurPlatformPos, ClosestSplinePos, SplineDist);

		UpdateAudio(DeltaTime, SplineDist);

		LastSplinePos = SplineDist;
	}

	void UpdateAudio(const float& DeltaTime, const float& SplineDist)
	{

		const bool bIsMoving = SplineDist != LastSplinePos;
		if(!bIsMoving && !bAudioPendingStop)
			return;	

		float NormalizedPlatformMoveProgress = HazeAudio::NormalizeRTPC01(SplineDist, 0.f, Spline.SplineLength);
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCranePlatformSplineProgress, NormalizedPlatformMoveProgress, 0.f);	

		if(bPlayImpactSoundOnSplineStart)
		{
			if(NormalizedPlatformMoveProgress == 0 && !bHasPlayedImpactSound && ImpactEvent != nullptr)
			{
				if(!bWaitForAwake)
				{
					HazeAkComp.HazePostEvent(ImpactEvent);
				}
				bHasPlayedImpactSound = true;
			}
		}			

		if(PlatformGravity == 0)
		{
			if(bAudioPendingStop)
			{
				HazeAkComp.HazePostEvent(OnStoppedAudio);
				HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneVerticalMovement, 0.f);
				bAudioPendingStop = false;
				return;
			}
		}
		else if(NormalizedPlatformMoveProgress == 0 && bAudioPendingStop)
		{
			HazeAkComp.HazePostEvent(OnStoppedAudio);
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneVerticalMovement, 0.f);
			bAudioPendingStop = false;
			return;
		}	

		if(bPlayImpactSoundOnSplineEnd)
		{						
			if(FMath::IsNearlyEqual(NormalizedPlatformMoveProgress, 1.f, 0.01f) && !bHasPlayedImpactSound && ImpactEvent != nullptr)
			{
				if(!bWaitForAwake)
				{
					HazeAkComp.HazePostEvent(ImpactEvent);
				}
				bHasPlayedImpactSound = true;
			}
		}

		if(NormalizedPlatformMoveProgress > 0.01 && NormalizedPlatformMoveProgress < 0.9 && bHasPlayedImpactSound)
		{
			bHasPlayedImpactSound = false;
		}

		if (PlatformGravity != 0.f && GrabbingPlayer == nullptr)
		{
			FVector Delta = PrevPosition - ActorLocation;
			float MaxSpeed = DeltaTime * PlatformGravity;
			float Speed = Delta.Size();

			if (Speed > 0.f)
			{
				float VerticalMovementRTPC = FMath::Clamp(FMath::Abs(Speed / MaxSpeed), 0.f, 1.f);
				HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneVerticalMovement, VerticalMovementRTPC, 0);
			}
		}	
	}
}
