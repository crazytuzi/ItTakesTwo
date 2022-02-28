import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.MagneticWrenchActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.WrenchSettings;

class UMagneticWrenchMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Wrench");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagneticWrenchActor Wrench;
	UHazeMovementComponent MoveComp;
	FMagneticWrenchSettings Settings;

	FVector OtherSideLocation;
	FVector NextOtherSideLocation;
	FQuat OtherSideRotation;
	FQuat NextOtherSideRotation;

	float NetSyncTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Wrench = Cast<AMagneticWrenchActor>(Owner);
		MoveComp = Wrench.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (Wrench.bDisableMovement)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Wrench.bDisableMovement)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OtherSideLocation = NextOtherSideLocation = Wrench.ActorLocation;
		OtherSideRotation = NextOtherSideRotation = Wrench.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Wrench");

		// Gravity
		Wrench.LinearVelocity += -MoveComp.WorldUp * Settings.Gravity * DeltaTime;

		// Friction
		// Integrating the friction using e^-Friction so I can use Lukes amazing Friction^Dt stuff
		Wrench.LinearVelocity *= FMath::Pow(FMath::Exp(-Settings.LinearFriction), DeltaTime);
		Wrench.AngularVelocity *= FMath::Pow(FMath::Exp(-Settings.AngularFriction), DeltaTime);

		// Apply rotational velocity
		FQuat Rotation = Wrench.ActorQuat;
		FQuat DeltaRotation = FQuat(Wrench.AngularVelocity.GetSafeNormal(), Wrench.AngularVelocity.Size() * DeltaTime);

		Rotation = DeltaRotation * Rotation;

		// Apply networking stuff
		if (Network::IsNetworked())
		{
			if (!Wrench.LinearVelocity.IsNearlyZero())
			{
				NetSyncTimer -= DeltaTime;
				if (NetSyncTimer <= 0.f)
				{
					NetSetOtherSide(HasControl(), Wrench.ActorLocation, Wrench.ActorQuat);
					NetSyncTimer = 0.5f;
				}
			}

			NextOtherSideLocation += Wrench.LinearVelocity * DeltaTime;

			// Interpolate other side location and rotation
			OtherSideLocation = FMath::VInterpTo(OtherSideLocation, NextOtherSideLocation, DeltaTime, 4.f);
			OtherSideRotation = FQuat::Slerp(OtherSideRotation, NextOtherSideRotation, DeltaTime * 4.f);

			FVector NextLocation = FMath::VInterpTo(Wrench.ActorLocation, OtherSideLocation, DeltaTime, 2.f);
			Rotation = FQuat::Slerp(Rotation, OtherSideRotation, DeltaTime * 2.f);

			FrameMove.ApplyDeltaWithCustomVelocity(NextLocation - Wrench.ActorLocation, FVector::ZeroVector);
		}

		// Apply linear velocity
		FrameMove.ApplyVelocity(Wrench.LinearVelocity);
		FrameMove.SetRotation(Rotation);

		MoveComp.Move(FrameMove);
		Wrench.LinearVelocity = MoveComp.Velocity;
	}

	UFUNCTION(NetFunction)
	void NetSetOtherSide(bool ControlSide, FVector Location, FQuat Rotation)
	{
		if (HasControl() == ControlSide)
			return;

		NextOtherSideLocation = Location;
		NextOtherSideRotation = Rotation;
	}
}
