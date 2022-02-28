import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetWindWalkComponent;

class UWindWalkMagnetCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"WindWalk");
	default CapabilityDebugCategory = n"WindWalk";
//	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 79;

	AHazePlayerCharacter Player;
	UWindWalkComponent WindWalkComp;
	UMagneticPlayerComponent PlayerMagnetComp;
	UMagnetWindWalkComponent ActiveMagnet;

	FRotator PreviousRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		WindWalkComp = UWindWalkComponent::GetOrCreate(Player);
		PlayerMagnetComp = UMagneticPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkActivation::DontActivate;		

		if (!Player.IsAnyCapabilityActive(FMagneticTags::PlayerGenericMagnetCapability))
			return EHazeNetworkActivation::DontActivate;

		auto WindWalkMagnet = Cast<UMagnetWindWalkComponent>(PlayerMagnetComp.GetActivatedMagnet());
		if (WindWalkMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

	//	if(!WindWalkMagnet.IsInfluencedBy(Player))
	//		return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkDeactivation::DeactivateLocal;		

		if (!Player.IsAnyCapabilityActive(FMagneticTags::PlayerGenericMagnetCapability))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	/*
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	*/
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		/*
		ActiveMagnet = Cast<UMagnetWindWalkComponent>(PlayerMagnetComp.GetTargetedMagnet());
		PlayerMagnetComp.ActivateMagnetLockon(ActiveMagnet, this);
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);
		*/
		ActiveMagnet = Cast<UMagnetWindWalkComponent>(PlayerMagnetComp.GetActivatedMagnet());

		PreviousRotation = ActiveMagnet.WorldRotation;

		Player.BlockCapabilities(n"WindWalkDash", this);
		Player.BlockCapabilities(n"WindWalkJump", this);

		WindWalkComp.bIsHoldingOntoMagnetPole = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		/*
		PlayerMagnetComp.DeactivateMagnetLockon(this);
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
		*/

		// Clear magnet delta
		PlayerMagnetComp.PlayerMagnet.ActivatedMagnetMovementDelta = 0.f;
		PreviousRotation = FRotator::ZeroRotator;

		Player.UnblockCapabilities(n"WindWalkDash", this);
		Player.UnblockCapabilities(n"WindWalkJump", this);

		WindWalkComp.bIsHoldingOntoMagnetPole = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"WindWalkGroundMovement");

		if (HasControl())
		{
			// Update player distance to magnet
			PlayerMagnetComp.UpdateActiveMagnet(ActiveMagnet);

			// Update magnet delta
			PlayerMagnetComp.PlayerMagnet.ActivatedMagnetMovementDelta = PreviousRotation.GetManhattanDistance(ActiveMagnet.WorldRotation);
			PreviousRotation = ActiveMagnet.WorldRotation;

			if (!WindWalkComp.bIsWindWalking)
				return;

			WindWalkComp.GroundNormal = MoveComp.DownHit.Normal;

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

			FVector ToMagnet = ActiveMagnet.GetWorldLocation() - Player.GetActorLocation();
			ToMagnet = ToMagnet.ConstrainToPlane(WindWalkComp.GroundNormal);
			float Distance = ToMagnet.Size();
			ToMagnet.Normalize();	
			float ForceFactor = Distance / 2000.f;
			ForceFactor = FMath::Pow(ForceFactor, 4);

			FVector Velocity = MoveComp.Velocity;
			
			FVector WindDirection = WindWalkComp.CurrentForce;
			WindDirection = WindDirection.ConstrainToPlane(WindWalkComp.GroundNormal);
			WindDirection.Normalize();	

			float RingAngleDot = WindDirection.DotProduct(ToMagnet);

			RingAngleDot = RingAngleDot * 0.5 + 0.5;
			RingAngleDot *= 4.f;

			/* Reduce angle if other player is attached 
			if (Player.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionPerchCapability))
				RingAngleDot *= 8.f;
			*/

			if (!Input.IsNearlyZero())
				RingAngleDot = FMath::Pow(RingAngleDot, 4);

			Velocity += WindDirection * Math::Saturate(RingAngleDot) * WindWalkComp.CurrentForce.Size() * DeltaTime;

		//	Print("RingAngleDot: " + (WindDirection * RingAngleDot * WindWalkComp.CurrentForce.Size()).Size());

			if (MoveComp.IsAirborne())
				Velocity += MoveComp.Gravity * 2.f * DeltaTime;

			FVector Acceleration = WindWalkComp.Acceleration;

			if (Player.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionPerchCapability))
				Acceleration *= 0.8;

			Velocity += Input * Acceleration * DeltaTime;
			Velocity -= Velocity * WindWalkComp.Drag * DeltaTime;
			Velocity += WindWalkComp.CurrentForce * Math::Saturate(1 - ForceFactor) * DeltaTime;
			Velocity += ToMagnet * 8000.f * Math::Saturate(ForceFactor - 1.f) * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.ApplyTargetRotationDelta();
			FrameMove.SetRotation(ToMagnet.ToOrientationQuat());
			MoveComp.SetTargetFacingDirection(ToMagnet);

			MoveCharacter(FrameMove, n"WindWalk");

			CrumbComp.LeaveMovementCrumb();	
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"WindWalk");
		}
	}

	void PrintVector(FVector Vector, FLinearColor Color)
	{
		System::DrawDebugLine(Player.GetActorLocation() + FVector::UpVector * 100.f, Player.GetActorLocation() + Vector.GetSafeNormal() * 500.f + FVector::UpVector * 100.f, Color);
	}
}
