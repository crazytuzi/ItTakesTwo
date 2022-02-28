import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtableComponent;
import Peanuts.Spline.SplineComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Spline.SplineActor;
import Peanuts.Movement.SplineLockStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadbuttingDinoAnimationDataComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Interactions.InteractionComponent;
import Vino.Movement.SplineLock.SplineLockProcessor;

settings HeadButtingDinoDefaultSettings for UMovementSettings
{
	HeadButtingDinoDefaultSettings.MoveSpeed = 1000.f;
}

class AHeadButtingDino : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComponent;
	default MoveComponent.DefaultMovementSettings = HeadButtingDinoDefaultSettings;

	UPROPERTY(DefaultComponent)
	UHeadbuttingDinoAnimationDataComponent AnimationData;

	UPROPERTY(DefaultComponent)
	UInteractionComponent Interaction;

	UPROPERTY(DefaultComponent)
	USceneComponent Jumplocation;


	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY()
	UAnimSequence JumpOnMay;

	UPROPERTY()
	UAnimSequence JumpOnCody;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset CodyLocomotionStateMachineAsset;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset MayLocomotionStateMachineAsset;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset HeadbuttingDinoLocomotionStateMachineAsset;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent CrushCapsule;

	UPROPERTY(DefaultComponent , Attach = Body)
	USceneComponent RidingPosition;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncAlphaSpeed;

	FVector MoveDirection;
	FVector DesiredMovedirection;

	UPROPERTY()
	float ForwardSpeedAlpha;

	UPROPERTY()
	bool IsHeadButting = false;

	UPROPERTY()
	bool ShouldPerformFailedHeadbutt = false;

	UPROPERTY()
	bool bJumpedOn = false;
	
	float HeadButtingTimer;
	
	UPROPERTY(BlueprintReadWrite)
	bool bWasCrushed = false;

	bool bIsHeadButtingOnRemoteSide = false;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapabilityType;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCameraCapabilityType;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent Body;

	UPROPERTY()
	AHazeCameraActor Camera;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter RidingPlayer;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DinoFallImpactAudioEvent;

	USplineLockComponent SplineLockComp;

	FHazeAcceleratedFloat DinoSpeed;
	FHazeAcceleratedFloat DinoMoveAlpha;

	TArray<UHeadButtableComponent> OverlappingHeadButtableComponents;
	TArray<UHeadButtableComponent> FlippingHeadbuttableComponents;

	UPROPERTY()
	AActor HeadbuttTrigger;

	bool DisableMovement = false;
	bool bCanSlam = true;

	bool bDinoIsAirborne = false;

	UPROPERTY()
	ASplineActor Splineactor;

	UHazeSplineComponent SplineComponent;

	TArray<UPrimitiveComponent> IgnoredFallComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComponent.Setup(CapsuleComponent);
		SplineComponent = Splineactor.Spline;
		SplineLockComp = USplineLockComponent::GetOrCreate(this);
		
		MoveComponent.UseCollisionSolver(MoveComponent.ControlSideDefaultCollisionSolver, MoveComponent.RemoteSideDefaultCollisionSolver);
		FRotator SplineRotation;
		SplineRotation = Math::MakeRotFromX(TangentAtSplinePoint);

		SetActorLocation(ClosestPointOnSpline);
		SetActorRotation(SplineRotation);

		if (HeadbuttingDinoLocomotionStateMachineAsset != nullptr)
		{
			Body.AddLocomotionAsset(HeadbuttingDinoLocomotionStateMachineAsset, this);
		}

		FConstraintSettings DinoConstraint;
		DinoConstraint.SplineToLockMovementTo = SplineComponent;
		DinoConstraint.ConstrainType = EConstrainCollisionHandlingType::FreeVertical;
		SplineLockComp.LockOwnerToSpline(DinoConstraint);

		auto SplineLockProcessor = USplineLockProcessor();
		SplineLockProcessor.SplineLockComp = SplineLockComp;
		MoveComponent.UseDeltaProcessor(SplineLockProcessor, this);

		Capability::AddPlayerCapabilityRequest(RequiredCapabilityType.Get());
		Capability::AddPlayerCapabilityRequest(RequiredCameraCapabilityType.Get());
	}

    UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapabilityType.Get());
		Capability::RemovePlayerCapabilityRequest(RequiredCameraCapabilityType.Get());
	}

	UFUNCTION(BlueprintEvent)
	void JumpedOnDino()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void OnJumpedOff()
	{

	}

	FVector GetClosestPointOnSpline() property
	{
		float DistanceAtSplineLocation = SplineComponent.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		return SplineComponent.GetLocationAtDistanceAlongSpline(DistanceAtSplineLocation, ESplineCoordinateSpace::World);
	}

	FVector GetTangentAtSplinePoint() property
	{
		float DistanceAtSplineLocation = SplineComponent.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		return SplineComponent.GetTangentAtDistanceAlongSpline(DistanceAtSplineLocation, ESplineCoordinateSpace::World);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetIsHeadButting(TArray<UHeadButtableComponent> ControlSideHeadbuttlableComponents)
	{
		FlippingHeadbuttableComponents = ControlSideHeadbuttlableComponents;

		if (ControlSideHeadbuttlableComponents.Num() == 0)
		{
			PlayFailedHeadButtAnimation();
		}
		else
		{
			PlayHeadButt();
		}

		DisableDinoCraneEatOtherPlayer(this);
	}

	void PlayHeadButt()
	{
		IsHeadButting = true;
		bIsHeadButtingOnRemoteSide = true;

		for (auto HeadButtablecomponent : FlippingHeadbuttableComponents)
		{
			if (HeadButtablecomponent.DinoPlatform != nullptr)
			{
				HeadButtablecomponent.DinoPlatform.Interaction.Disable(n"IsFlipping");
			}
		}

		if (!HasControl() || !Network::IsNetworked())
		{
			System::SetTimer(this, n"FinishedHeadButtAnimation", FMath::Max(0.85f - Network::GetPingRoundtripSeconds(), KINDA_SMALL_NUMBER), bLooping = false);
		}

		PlayShakingGroundEffect();
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishedHeadButtAnimation()
	{
		TArray<UHeadButtableComponent> ValidComponents;

		for (auto Component : FlippingHeadbuttableComponents)
		{
			if (Component.DinoPlatform == nullptr)
			{
				ValidComponents.Add(Component);
			}
			else if (Component.DinoPlatform.GrabbingPlayer == nullptr)
			{
				ValidComponents.Add(Component);
			}
		}

		NetRemoteSideHeadbuttingFinished(ValidComponents);
	}

	//This is super... Not allowed. Apologies.
	TArray<UHeadButtableComponent> _ValidComponents;

	UFUNCTION(NetFunction)
	void NetRemoteSideHeadbuttingFinished(TArray<UHeadButtableComponent> ValidComponents)
	{
		_ValidComponents  = ValidComponents;
		if (!HasControl())
		{
			float DelayTime = 0.85f - (0.85 - Network::GetPingRoundtripSeconds());
			System::SetTimer(this, n"PlayHeadButtEffectsOnComponents", DelayTime, false);
		}

		else
		{
			PlayHeadButtEffectsOnComponents();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayHeadButtEffectsOnComponents()
	{
		for (UHeadButtableComponent HeadButtable : _ValidComponents)
		{
			HeadButtable.PlayHeadButtEffects();
		}

		System::SetTimer(this, n"SetHeadButInputIsValid", 1.f, false);

		_ValidComponents.Empty();
	}

	UFUNCTION(NotBlueprintCallable)
	void SetHeadButInputIsValid()
	{
		bIsHeadButtingOnRemoteSide = false;

		for (auto HeadButtablecomponent : FlippingHeadbuttableComponents)
		{
			if (HeadButtablecomponent.DinoPlatform != nullptr)
			{
				HeadButtablecomponent.DinoPlatform.Interaction.Enable(n"IsFlipping");
			}
		}
	}

	void PlayFailedHeadButtAnimation()
	{
		IsHeadButting = true;
		ShouldPerformFailedHeadbutt = true;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetIsNotHeadButting()
	{
		ShouldPerformFailedHeadbutt = false;
		IsHeadButting = false;
		EnableDinoCraneEatOtherPlayer(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!DisableMovement)
		{
			if (RidingPlayer != nullptr)
			{
				HandleMovement(DeltaTime);
			}

			if (IsHeadButting && HasControl())
			{
				
				HeadButtingTimer += DeltaTime;

				if (HeadButtingTimer > 1.f)
				{
					HeadButtingTimer = 0;
					NetSetIsNotHeadButting();
				}
			}
		}
	}

	void HandleMovement(float Delta)
	{
		if(!MoveComponent.CanCalculateMovement())
			return;

		FHazeFrameMovement Movement = MoveComponent.MakeFrameMovement(n"MoveDino");

		if(HasControl())
		{
			DesiredMovedirection = DesiredMovedirection.GetClampedToSize(0.4f, 1.f);
			float DotToForward = GetActorForwardVector().DotProduct(DesiredMovedirection);
			DinoSpeed.AccelerateTo(MoveComponent.MoveSpeed * DotToForward, 0.75f, Delta);
			FVector MoveDelta = ActorForwardVector * DinoSpeed.Value * Delta;
			
			if (MoveComponent.IsGrounded() && MoveComponent.PreviousImpacts.DownImpact.bBlockingHit)
			{
				const float LengthOfInput = MoveDelta.Size();
				MoveDelta = MoveDelta.ConstrainToPlane(MoveComponent.PreviousDownHit.Normal).GetSafeNormal() * LengthOfInput;

				for (auto Primitive : IgnoredFallComponents)
					MoveComponent.StopIgnoringComponent(Primitive);

				IgnoredFallComponents.Reset();
			}
			else if (MoveComponent.DownHit.bBlockingHit)
			{
				MoveComponent.StartIgnoringComponent(MoveComponent.DownHit.Component);
				IgnoredFallComponents.Add(MoveComponent.DownHit.Component);
			}
			
			FRotator SplineRotation = Math::MakeRotFromX(TangentAtSplinePoint);

			if(!IsHeadButting)
			{
				Movement.ApplyDelta(MoveDelta);
				Movement.SetRotation(SplineRotation.Quaternion());
			}

			if (MoveComponent.IsAirborne())
			{
				Movement.ApplyActorVerticalVelocity();
				Movement.ApplyGravityAcceleration();
				bDinoIsAirborne = true;
			}
			
			// Used for animations
			FVector InputDelta = CalculateInputVector(DesiredMovedirection);
			DinoMoveAlpha.AccelerateTo(ActorForwardVector.DotProduct(InputDelta *  MoveComponent.MoveSpeed) / MoveComponent.MoveSpeed, 0.5f, Delta);
			ForwardSpeedAlpha = DinoMoveAlpha.Value;
			SyncAlphaSpeed.Value = ForwardSpeedAlpha;
			Movement.FlagToMoveWithDownImpact();

			if (MoveComponent.IsGrounded() && bDinoIsAirborne)
			{
				HazeAkComp.HazePostEvent(DinoFallImpactAudioEvent);
				bDinoIsAirborne = false;
			}

		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComponent.ConsumeCrumbTrailMovement(Delta, ConsumedParams);
			ForwardSpeedAlpha = SyncAlphaSpeed.Value;
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveComponent.Move(Movement);
		CrumbComponent.LeaveMovementCrumb();

		AnimationData.bIsGrounded = MoveComponent.IsGrounded();
	}

	void SetMeshTilt()
	{
		FRotator LocalRot = Body.RelativeRotation;

		LocalRot.Pitch = FMath::Lerp(0.f,-10.f, ForwardSpeedAlpha * 1);

		Body.RelativeRotation = LocalRot;
	}

	FVector CalculateInputVector(FVector InputVector)
	{
		FVector Output = FVector::ZeroVector;

		FVector SplineTangent = SplineComponent.FindTangentClosestToWorldLocation(ActorLocation, ESplineCoordinateSpace::World).GetSafeNormal();
		SplineTangent = SplineTangent.ConstrainToPlane(MoveComponent.WorldUp).GetSafeNormal();

		const FVector WorldSpaceInput = InputVector;
		const float DotInputAndTangent = SplineTangent.DotProduct(WorldSpaceInput);

		if (FMath::Abs(DotInputAndTangent) > 0.25f)
		{
			Output = SplineTangent.GetSafeNormal() * DotInputAndTangent;
		}

		return Output;
	}

	UFUNCTION()
	void SetMovementEnabled(bool MovementEnabled)
	{
		DisableMovement = !MovementEnabled;
	}

	bool GetCanSlam() property
	{
		return (!IsHeadButting && bCanSlam);
	}

	void HeadButt()
	{
		if (!IsHeadButting && bCanSlam && !bIsHeadButtingOnRemoteSide)
		{
			if(HasControl())
			{
 				NetSetIsHeadButting(OverlappingHeadButtableComponents);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void PlayShakingGroundEffect()
	{

	}

	UFUNCTION(BlueprintEvent)
	void TriggerDeathEffets(FTransform RespawnPosition)
	{
		
	}

	UFUNCTION()
	void JumpOnDino(AHazePlayerCharacter Player, bool bShouldSnap)
	{
		if (bShouldSnap)
		{
			SetPlayerRiding(Player);
			Player.SetAnimBoolParam(n"SkipDinoEnter", true);
			SetAnimBoolParam(n"SkipDinoEnter", true);
		}
		else
		{
			FHazeJumpToData JumpData;
			JumpData.Transform = Jumplocation.WorldTransform;
			JumpData.AdditionalHeight = 220;
			FHazeDestinationEvents OnFinished;
			OnFinished.OnDestinationReached.BindUFunction(this, n"SetPlayerRiding");
			JumpTo::ActivateJumpTo(Player, JumpData, OnFinished);
		}
	}
	
	UFUNCTION()
	void SetPlayerRiding(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Player", Player);
		UHazeCrumbComponent::Get(Player).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"SetPlayerRidingCrumb"), CrumbParams);
	}

	UFUNCTION()
	void SetPlayerRidingCrumb(const FHazeDelegateCrumbData Data)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Data.GetObject(n"Player"));
		SnapPlayerToDino(Player);
	}

	UFUNCTION()
	void SnapPlayerToDino(AHazePlayerCharacter Player)
	{
		RidingPlayer = Player;
		RidingPlayer.SetCapabilityAttributeObject(n"HeadbuttingDino", this);
		RidingPlayer.AttachToComponent(Body, n"Root", EAttachmentRule::SnapToTarget);
		bJumpedOn = true;

		HazeAudio::SetPlayerPanning(HazeAkComp, Player);

		if (Player.IsCody())
		{
			Player.AddLocomotionAsset(CodyLocomotionStateMachineAsset, this);
		}
		else
		{
			Player.AddLocomotionAsset(MayLocomotionStateMachineAsset, this);
		}

		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		JumpedOnDino();
		RequestControlSide(Player);
	}

	void RequestControlSide(AHazePlayerCharacter Player)
	{
		if (HasControl())
		{
			return;
		}

		else
		{
			NetSendControlRequest(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetSendControlRequest(AHazePlayerCharacter Player)
	{
		if(HasControl())
		{
			NetRespondSetControlRequest(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetRespondSetControlRequest(AHazePlayerCharacter Player)
	{
		SetControlSide(Player);
	}

	void SetMoveInput(FVector DesiredMoveDir)
	{
		DesiredMovedirection = DesiredMoveDir;	
	}

	UFUNCTION(BlueprintCallable)
	void ForceJumpoff()
	{
		RidingPlayer.SetCapabilityActionState(n"JumpOffHeadbuttingDino", EHazeActionState::Active);
	}
	
	void JumpOff()
	{
		ensure(!IsHeadButting);

		RidingPlayer.SetCapabilityAttributeObject(n"HeadbuttingDino", nullptr);
		
		RidingPlayer.DetachFromActor(EDetachmentRule::KeepWorld);
		RidingPlayer.ClearLocomotionAssetByInstigator(this);
		OnJumpedOff();

		if (HasControl())
			NetSetIsNotHeadButting();
	}
}

void DisableHeadButtingDinoSlam()
{
	TArray<AHeadButtingDino> Dinos;
	GetAllActorsOfClass(Dinos);

	for(auto Dino : Dinos)
	{
		ensure(!Dino.IsHeadButting);
		Dino.bCanSlam = false;
	}
}

void EnableHeadButtingDinoSlam()
{
	TArray<AHeadButtingDino> Dinos;
	GetAllActorsOfClass(Dinos);

	for(auto Dino : Dinos)
	{
		ensure(!Dino.IsHeadButting);
		Dino.bCanSlam = true;
	}
}
