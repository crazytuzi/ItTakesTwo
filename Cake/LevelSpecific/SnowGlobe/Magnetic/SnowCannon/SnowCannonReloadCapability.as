import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.SnowCannonActor;

class USnowCannonReloadCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityTags.Add(n"MagnetCannonReloadCapability");

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	ASnowCannonActor SnowCannonOwner;
	UStaticMeshComponent ReloadProjectile;

	FVector Velocity;

	FQuat RotationOrigin;
	float RotationSpeed;
	float LerpAlpha;

	const float CoilBurst = 3200.f;

	bool bIsSpawning;
	bool bLocationDone;
	bool bRotationDone;

	bool bSilentReload;
	bool bSilentReloadDone;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowCannonOwner = Cast<ASnowCannonActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"SilentReload"))
			return EHazeNetworkActivation::ActivateLocal;

		if(!SnowCannonOwner.bInCooldown)
			return EHazeNetworkActivation::DontActivate;

		if(SnowCannonOwner.CooldownTimer < SnowCannonOwner.ThumperShootAccelerationDuration * 1.2f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Teleport fake magnet mesh to start
		ReloadProjectile = SnowCannonOwner.FakeMagnetProjectile;
		ReloadProjectile.AttachToComponent(SnowCannonOwner.ReloadStart);
		ReloadProjectile.SetVisibility(true);

		if(IsActioning(n"SilentReload"))
		{
			bSilentReload = true;
		}
		else
		{
			Velocity = SnowCannonOwner.ActorUpVector * CoilBurst;
			RotationSpeed = FMath::RandRange(280.f, 400.f);

			bIsSpawning = true;
			SnowCannonOwner.OnReloadStarted.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bSilentReload)
		{
			ReloadProjectile.AttachToComponent(SnowCannonOwner.AmmoAttach);
			bSilentReloadDone = true;

			return;
		}

		if(bIsSpawning)
		{
			Velocity += Game::GetCody().ActorGravity * DeltaTime;
			ReloadProjectile.AddRelativeLocation(Velocity * DeltaTime);

			if(Velocity.Z < -1000.f)
			{
				bIsSpawning = false;
				ReloadProjectile.AttachToComponent(SnowCannonOwner.AmmoAttach, AttachmentRule = EAttachmentRule::KeepWorld);
			}

			// ReloadProjectile.AddLocalRotation(FRotator(-800.f * DeltaTime, 0.f, 00.f * DeltaTime));

			RotationOrigin = ReloadProjectile.RelativeRotation.Quaternion();
		}
		else
		{
			if(!bLocationDone)
			{
				FVector MagnetToSlot = -(ReloadProjectile.RelativeLocation).GetSafeNormal();
				float DistanceToSlot = ReloadProjectile.RelativeLocation.Size();
				Velocity += MagnetToSlot * FMath::Square(DistanceToSlot) * 1.5f * DeltaTime;

				FVector NextLocation = ReloadProjectile.RelativeLocation + Velocity * DeltaTime;
				if(ReloadProjectile.RelativeLocation.Distance(NextLocation) > DistanceToSlot || DistanceToSlot < 60.f)
				{
					bLocationDone = true;
					NextLocation = FVector::ZeroVector;

					SnowCannonOwner.OnReloadCompleted.Broadcast();
				}

				ReloadProjectile.SetRelativeLocation(NextLocation);
			}

			if(!bRotationDone)
			{
				LerpAlpha = Math::Saturate(LerpAlpha + DeltaTime * 10.f);

				FQuat TargetRotation = Math::MakeQuatFromXZ(FQuat::Identity.AxisX, RotationOrigin.GetAxisZ());
				FQuat LocalRotation = FQuat::Slerp(RotationOrigin, TargetRotation, LerpAlpha);


				ReloadProjectile.SetRelativeRotation(LocalRotation.Rotator());

				if(LerpAlpha >= 1.f)
					bRotationDone = true;
			}
		}

		if(!bLocationDone)
			ReloadProjectile.AddLocalRotation(FRotator(0.f, 0.f, -RotationSpeed * DeltaTime));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bSilentReloadDone)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!bLocationDone)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!bRotationDone)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(SnowCannonOwner.bInCooldown)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ReloadProjectile = nullptr;

		LerpAlpha = 0.f;

		bIsSpawning = false;
		bLocationDone = false;
		bRotationDone = false;
		bSilentReload = false;
		bSilentReloadDone = false;
	}
}