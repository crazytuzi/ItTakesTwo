import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.MagneticWrenchActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.WrenchSettings;

class UMagneticWrenchPhysicsCapability : UHazeCapability
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

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Wrench = Cast<AMagneticWrenchActor>(Owner);
		MoveComp = Wrench.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wrench.bIsAttachedToNut)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wrench.bIsAttachedToNut)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateCollisionFor(Wrench.LeftCollision, DeltaTime);
		UpdateCollisionFor(Wrench.RightCollision, DeltaTime);
	}

	void UpdateCollisionFor(UPrimitiveComponent Collision, float DeltaTime)
	{
		FHazeHitResult Hit;

		FVector Location = Collision.WorldLocation;
		FVector Delta = Wrench.LinearVelocity * DeltaTime;

		Collision.SweepTrace(Location, Location + Delta, Hit);
		if (Hit.bStartPenetrating)
		{
			FVector DepenVector = Hit.Normal * Hit.PenetrationDepth;
			System::DrawDebugLine(Location, Location + DepenVector, FLinearColor::Red, Thickness = 6.f);

			Wrench.ApplyAngularForce(Location, Hit.Normal * Hit.PenetrationDepth * 5.f, DeltaTime);
			Wrench.AddActorWorldOffset(Hit.Normal * Hit.PenetrationDepth * 10.f * DeltaTime);
		}
		if (Hit.bBlockingHit)
		{
			Wrench.ApplyAngularForce(Location, Hit.Normal * Wrench.LinearVelocity.Size(), DeltaTime);
		}
	}
}
