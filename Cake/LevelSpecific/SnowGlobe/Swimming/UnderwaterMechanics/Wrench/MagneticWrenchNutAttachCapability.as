import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.MagneticWrenchActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.WrenchSettings;
import Peanuts.Audio.AudioStatics;

class UMagneticWrenchNutAttachCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Wrench");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 90;

	AMagneticWrenchActor Wrench;
	UHazeMovementComponent MoveComp;
	FMagneticWrenchSettings Settings;

	AWrenchNutActor Nut;
	float NutRotationSpeed = 0.f;
	float NutRotation = 0.f;

	float SyncTime = 0.f;
	float OtherSideNutRotation = 0.f;
	float SyncFrequency = 5.f;

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

		if (Wrench.ActiveNut == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    FVector ToWrench = Wrench.ActorLocation - Wrench.ActiveNut.AttachSocket.WorldLocation;
	    FVector UpVector = Wrench.ActiveNut.AttachSocket.UpVector;

	    float VertOffset = ToWrench.DotProduct(UpVector);
	    if (VertOffset < Settings.AttachVertMinOffset)
	        return EHazeNetworkActivation::DontActivate;

	    if (VertOffset > Settings.AttachVertMaxOffset)
	        return EHazeNetworkActivation::DontActivate;

	    float HoriOffset = ToWrench.ConstrainToPlane(UpVector).Size();
	    if (HoriOffset > Settings.AttachHoriOffset)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (Nut.bIsFullyScrewed)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (NutRotation >= Nut.ScrewGoal)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Nut = Wrench.ActiveNut;

		Wrench.AttachToComponent(Nut.AttachSocket, NAME_None, EAttachmentRule::KeepWorld);
		Wrench.Collision.SetCollisionProfileName(n"NoCollision");

		NutRotationSpeed = 0.f;
		NutRotation = 0.f;
		OtherSideNutRotation = 0.f;

		Wrench.bIsAttachedToNut = true;

		Nut.BP_WrenchInPlace();

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Launch the wrench off the nut, and transfer the NutRotations speed into angular velocity
		Wrench.LinearVelocity = Nut.ActorUpVector * Settings.ScrewCompleteLinearImpulse;
		Wrench.AngularVelocity = Nut.ActorUpVector * NutRotationSpeed * DEG_TO_RAD;

		// Add a random kick to the NutRotation so that it looks a bit more natural
		float RandomAngle = FMath::RandRange(0.f, TAU);
		FVector RandomVector = FVector(FMath::Cos(RandomAngle), FMath::Sin(RandomAngle), 0.f);
		Wrench.AngularVelocity += RandomVector * 1.f;

		Wrench.DetachRootComponentFromParent();

		Wrench.Collision.SetCollisionProfileName(n"BlockAllDynamic");

		Nut.CompleteScrew();
		Nut = nullptr;

		Wrench.bIsAttachedToNut = false;

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Network::IsNetworked())
		{
			if (!FMath::IsNearlyZero(NutRotationSpeed))
			{
				SyncTime -= DeltaTime;
				if (SyncTime <= 0.f)
				{
					NetSetOtherSideNutRotation(HasControl(), NutRotation);
					SyncTime = 1.f / SyncFrequency;
				}
			}

			if (OtherSideNutRotation > NutRotation)
			{
				NutRotation = FMath::FInterpTo(NutRotation, OtherSideNutRotation, DeltaTime, 2.f);
			}
		}

		ApplyNutRotationSpeedForMagnet(Wrench.RedMagnet, DeltaTime);
		ApplyNutRotationSpeedForMagnet(Wrench.BlueMagnet, DeltaTime);

		NutRotationSpeed -= NutRotationSpeed * Settings.AttachFriction * DeltaTime;

		FVector CurrentLocation = Wrench.RootComponent.RelativeLocation;
		FVector Location = CurrentLocation;
		Location = FMath::VInterpTo(Location, FVector::ZeroVector, DeltaTime, Settings.AttachInterpSpeed);

		NutRotation += NutRotationSpeed * DeltaTime;
		if (NutRotation < 0.f)
		{
			NutRotation = 0.f;
			NutRotationSpeed = 0.f;
		}

		Nut.SetNutRotation(NutRotation);

		FHitResult Result;
		Wrench.SetActorRelativeLocation(Location, false, Result, false);

		// For rotations, we wanna eliminate pitch and roll, but towards the _closest_ 180 degree resting place
		// So the math becomes a little bit tricky
		FQuat Rotation = Wrench.RootComponent.RelativeTransform.Rotation;
		FVector Forward = Rotation.ForwardVector;
		Forward = Forward.ConstrainToPlane(FVector::UpVector);

		// Either up or down, depending on where the current up-vector is pointing
		FVector Up = FVector::UpVector * FMath::Sign(Rotation.UpVector.DotProduct(FVector::UpVector));

		FQuat TargetRotation = Math::MakeQuatFromXZ(Forward, Up);
		Rotation = FQuat::Slerp(Rotation, TargetRotation, Settings.AttachInterpSpeed * DeltaTime);
		Wrench.RootComponent.SetRelativeRotation(Rotation);

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Wrench");
		MoveComp.Move(FrameMove);

		//Audio velocity rtpc
		Nut.HazeAkCompNut.SetRTPCValue("Rtpc_SnowGlobe_Lake_WrenchNut_Screw_Velocity", NutRotationSpeed);

		//Print("Velo" + NutRotationSpeed);

		if(FMath::Abs(NutRotationSpeed) > 10)
		Nut.BP_StartTurning();
		if(FMath::Abs(NutRotationSpeed) < 3)
		Nut.BP_StopTurning();

	}

	void ApplyNutRotationSpeedForMagnet(UMagneticWrenchComponent Magnet, float DeltaTime)
	{
		FVector Offset = Magnet.WorldLocation - Wrench.ActorLocation;
		FVector DirForce = Magnet.GetDirectionalForceFromAllInfluencers();

		FVector Torque = Offset.CrossProduct(DirForce);
		float TorqueDirection = Torque.DotProduct(Nut.ActorUpVector);
		TorqueDirection = FMath::Sign(TorqueDirection);

		float Acceleration = Wrench.AreBothPlayersActive() ? Settings.AttachAcceleration_Both : Settings.AttachAcceleration_Single;
		NutRotationSpeed += TorqueDirection * Acceleration * DeltaTime;
	}

	UFUNCTION(NetFunction)
	void NetSetOtherSideNutRotation(bool bControlSide, float InNutRotation)
	{
		if (HasControl() == bControlSide)
			return;

		OtherSideNutRotation = InNutRotation;
	}
}
