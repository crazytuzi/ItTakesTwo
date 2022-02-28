import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Peanuts.Animation.Features.LocomotionFeaturePlasmaBall;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Peanuts.Network.RelativeCrumbLocationCalculator;
import Cake.LevelSpecific.PlayRoom.SpaceStation.PlasmaBallEffectComponent;

UCLASS(Abstract)
class APlasmaBall : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USphereComponent RootComp;
	default RootComp.SphereRadius = 500.f;
	default RootComp.CollisionProfileName = n"IgnorePlayerCharacter";

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent PlasmaBallMesh;
	default PlasmaBallMesh.CollisionProfileName = n"BlockOnlyPlayerCharacter";

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent KillTrigger;
	default KillTrigger.SphereRadius = 505.f;
	default KillTrigger.CollisionProfileName = n"PlayerTriggerOnly";

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UHazeTriggerComponent InteractionPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent DirectionArrow;
	default DirectionArrow.ArrowSize = 8.f;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SmoothSyncVectorComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 20000.f;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent CallbackComp;

	AHazePlayerCharacter InteractingPlayer;
	FVector2D CurrentPlayerInput;
	
	float MaximumPushingPower = 350.f;
	float MaximumRotationRate = 75.f;

	bool bInteracting = false;

	UPROPERTY()
	float InteractionVerticalOffset = 300.f;
	UPROPERTY()
	float InteractionHorizontalOffset = 400.f;

	FTransform InteractionTransform;

	FVector PushDirection;

	bool bMoving = false;

	FVector MovementDirection;
	FRotator CurRotationRate;

	float TheDot;

	UPROPERTY()
	ECharacterSize CurrentCodySize = ECharacterSize::Medium;

	UPROPERTY()
	ULocomotionFeaturePlasmaBall PlasmaBallFeature;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveWhileMediumTimeLike;
	FVector MoveWhileMediumStartLocation;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactForceFeedback;

	UPROPERTY(NotEditable)
	FVector BallVelocity = FVector::ZeroVector;

	UPROPERTY(NotEditable)
	float RotationRate = 0.f;

	bool bCollisonDetected = false;

	UPlasmaBallEffectComponent EffectComp;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Capability::AddPlayerCapabilityRequest(RequiredCapability.Get(), EHazeSelectPlayer::Cody);

		InteractingPlayer = Game::GetCody();
        SetupTriggerProperties(InteractionPoint);
		InteractionPoint.SetExclusiveForPlayer(EHazePlayer::Cody);

        FHazeTriggerActivationDelegate InteractionDelegate;
	    InteractionDelegate.BindUFunction(this, n"OnInteractionActivated");
		InteractionPoint.AddActivationDelegate(InteractionDelegate);

		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"RolledOver");

		MoveWhileMediumTimeLike.BindUpdate(this, n"UpdateMoveWhileMedium");
		MoveWhileMediumTimeLike.BindFinished(this, n"FinishMoveWhileMedium");

		SetControlSide(Game::GetCody());

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnBall");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeaveBall");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		SmoothSyncVectorComp.SetValue(ActorLocation);

		EffectComp = UPlasmaBallEffectComponent::Get(this);
    }

	UFUNCTION(NotBlueprintCallable)
	void LandOnBall(AHazePlayerCharacter Player, FHitResult Hit)
	{
		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
		CrumbComp.MakeCrumbsUseCustomWorldCalculator(URelativeCrumbLocationCalculator::StaticClass(), this, PlasmaBallMesh);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeaveBall(AHazePlayerCharacter Player)
	{
		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
		CrumbComp.RemoveCustomWorldCalculator(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability.Get(), EHazeSelectPlayer::Cody);
	}

	void UpdatePlayerInput(FVector2D Input)
	{
		CurrentPlayerInput = Input;
	}

	UFUNCTION()
	void RolledOver(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		float VertDist = ActorLocation.Z - OtherActor.ActorLocation.Z;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (VertDist > 400.f && Player != nullptr && bMoving && TheDot > 0 && Player.HasControl())
		{
			KillPlayer(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector Loc = InteractingPlayer.ActorLocation - ActorLocation;
		FVector Dir = Math::ConstrainVectorToPlane(Loc, FVector::UpVector);
		Dir = Dir.GetSafeNormal();
		PushDirection = Dir * -1;

		FVector MayLoc = InteractingPlayer.OtherPlayer.ActorLocation - ActorLocation;
		FVector MayDir = Math::ConstrainVectorToPlane(MayLoc, FVector::UpVector);
		MayDir = MayDir.GetSafeNormal();

		TheDot = MayDir.DotProduct(BallVelocity.GetSafeNormal());

		FVector CurVelocity = FVector::ZeroVector;
		
		if (bInteracting)
		{
			if (Game::GetCody().HasControl())
			{
				DirectionArrow.SetWorldRotation(PushDirection.Rotation());

				FVector DesiredMovementDirection = FVector(CurrentPlayerInput.X, CurrentPlayerInput.Y, 0.f);
				MovementDirection = FMath::VInterpTo(MovementDirection, DesiredMovementDirection, DeltaTime, 2.f);

				FVector MovementDelta = MovementDirection * MaximumPushingPower * DeltaTime;
				CurVelocity = MovementDelta;

				FHitResult HitResult;

				FVector CodyTraceStartLoc = Game::GetCody().ActorLocation + FVector(0.f, 0.f, Game::GetCody().CapsuleComponent.GetScaledCapsuleHalfHeight() + 5.f);
				TArray<AActor> ActorsToIgnore;
				ActorsToIgnore.Add(Game::GetCody());
				FHitResult CodyTraceHit;
				System::CapsuleTraceSingle(CodyTraceStartLoc, CodyTraceStartLoc + MovementDelta, Game::GetCody().CapsuleComponent.GetScaledCapsuleRadius(), Game::GetCody().CapsuleComponent.GetScaledCapsuleHalfHeight(), ETraceTypeQuery::Visibility, false,  ActorsToIgnore, EDrawDebugTrace::None, CodyTraceHit, true);
				if (CodyTraceHit.bBlockingHit)
					return;

				AddActorWorldOffset(MovementDelta, true, HitResult, false);

				if (HitResult.bBlockingHit)
				{
					if (!bCollisonDetected)
					{
						bCollisonDetected = true;
						Game::GetCody().PlayForceFeedback(ImpactForceFeedback, false, true, n"PlasmaBallImpact");
					}
					return;
				}
				else if (bCollisonDetected)
				{
					bCollisonDetected = false;
				}

				SmoothSyncVectorComp.SetValue(ActorLocation);

				FRotator BallRotation = FRotator(-CurrentPlayerInput.X, 0.f, CurrentPlayerInput.Y) * MaximumRotationRate * DeltaTime;
				CurRotationRate = FMath::RInterpTo(CurRotationRate, BallRotation, DeltaTime, 2.f);
				PlasmaBallMesh.AddWorldRotation(CurRotationRate);
			}
			else
			{
				FVector DistanceDif = SmoothSyncVectorComp.Value - ActorLocation;
				float RotationSpeedMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(0.1f, 10.f), FVector2D(0.f, 1.f), DistanceDif.Size());
				FVector DesiredDir = DistanceDif.GetSafeNormal();
				DirectionArrow.SetWorldRotation(DesiredDir.Rotation());
				FVector MovementDelta = DesiredDir * MaximumPushingPower * DeltaTime;
				CurVelocity = MovementDelta;
				SetActorLocation(SmoothSyncVectorComp.Value);
				FRotator BallRot = FRotator(-DesiredDir.X, 0.f, DesiredDir.Y);
				BallRot *= MaximumRotationRate * RotationSpeedMultiplier * DeltaTime;
				PlasmaBallMesh.AddWorldRotation(BallRot);
				
			}

			if (BallVelocity.Size() != 0)
				bMoving = true;
			else
				bMoving = false;
		}

		BallVelocity = CurVelocity;
		RotationRate = BallVelocity.Size();

        FVector InteractionLoc = FVector(ActorLocation.X, ActorLocation.Y, ActorLocation.Z - InteractionVerticalOffset);
		InteractionTransform = FTransform(PushDirection.Rotation(), InteractionLoc + Dir * (InteractionHorizontalOffset + 220) - FVector(0.f, 0.f, 500.f), FVector::OneVector);
        InteractionPoint.SetWorldLocation(InteractionLoc + Dir * InteractionHorizontalOffset);
	}

    UFUNCTION()
    void OnInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
    {	
		bInteracting = true;
		InteractionPoint.Disable(n"Occupied");
		FHazeAnimationDelegate OnOneShotFinished;
		OnOneShotFinished.BindUFunction(this, n"OneShotFinished");

		if (CurrentCodySize == ECharacterSize::Small)
		{
			Player.PlayEventAnimation(OnBlendingOut = OnOneShotFinished, Animation = PlasmaBallFeature.PlasmaBallSmall);
			FVector Loc = Player.ActorLocation;
			Loc.Z = ActorLocation.Z - 500.f;
			Player.SmoothSetLocationAndRotation(Loc, InteractionTransform.Rotator());
		}
		else if (CurrentCodySize == ECharacterSize::Medium)
		{
			Player.PlayEventAnimation(Animation = PlasmaBallFeature.PlasmaBallMedium);
			FVector Dir = (Player.ActorLocation - ActorLocation);
			Dir = Math::ConstrainVectorToPlane(Dir, FVector::UpVector);
			Dir.Normalize();
			FVector Loc = ActorLocation + (Dir * 435.f);
			Loc.Z = ActorLocation.Z - 500.f;
			Player.SmoothSetLocationAndRotation(Loc, InteractionTransform.Rotator());
			MoveWhileMediumStartLocation = ActorLocation;
			MoveWhileMediumTimeLike.PlayFromStart();
			EffectComp.SetCodyHandTracking(true);
		}
		else if (CurrentCodySize == ECharacterSize::Large)
		{
			Player.SetCapabilityAttributeObject(n"PlasmaBall", this);
			Player.SetCapabilityActionState(n"MovingPlasmaBall", EHazeActionState::Active);
			EffectComp.SetCodyHandTracking(true);
		}
    }

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveWhileMedium(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(MoveWhileMediumStartLocation, MoveWhileMediumStartLocation + (PushDirection * 50.f), CurValue);
		FRotator TargetRotation = FRotator(-PushDirection.Y * 5.f, ActorRotation.Yaw, -PushDirection.X * 5.f);
		FRotator Rot = FMath::LerpShortestPath(FRotator(0.f, ActorRotation.Yaw, 0.f), TargetRotation, CurValue);
		SetActorLocationAndRotation(CurLoc, Rot);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveWhileMedium()
	{
		InteractionCanceled();
	}

	UFUNCTION()
	void OneShotFinished()
	{
		InteractionCanceled();
	}

	void InteractionCanceled()
	{
		CurrentPlayerInput = FVector2D(0.f, 0.f);
		bMoving = false;
		bInteracting = false;
		InteractionPoint.Enable(n"Occupied");
		EffectComp.SetCodyHandTracking(false);
	}

    UFUNCTION()
    void SetupTriggerProperties(UHazeTriggerComponent TriggerComponent)
	{
		FHazeShapeSettings ActionShape;
		ActionShape.SphereRadius = 800.f;
		ActionShape.Type = EHazeShapeType::Sphere;

		FHazeShapeSettings FocusShape;
		FocusShape.Type = EHazeShapeType::Sphere;
		FocusShape.SphereRadius = 2500.f;

		FTransform ActionTransform;
		ActionTransform.SetScale3D(FVector(1.f));

		FHazeDestinationSettings MovementSettings;
	
		FHazeActivationSettings ActivationSettings;
		ActivationSettings.ActivationType = EHazeActivationType::Action;

		FHazeTriggerVisualSettings VisualSettings;
		VisualSettings.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

		TriggerComponent.AddActionShape(ActionShape, ActionTransform);
		TriggerComponent.AddFocusShape(FocusShape, ActionTransform);
		TriggerComponent.AddMovementSettings(MovementSettings);
		TriggerComponent.AddActivationSettings(ActivationSettings);
		TriggerComponent.SetVisualSettings(VisualSettings);
	}
}
