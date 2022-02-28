import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Camera.Actors.FollowViewFocusTrackerCamera;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

class UMusicFlyingReturnToVolumeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicFlying");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	UHazeCrumbComponent CrumbComp;
	UMusicalFlyingComponent FlyingComp;
	AFollowViewFocusTrackerCamera ExitCamera;
	UHazeMovementComponent MoveComp;
	UMusicalFlyingSettings Settings;
	UMusicFlyingReturnToVolumeSettings ReturnToVolumeSettings;

	float Elapsed = 0.0f;
	float ExitElapsed = 0.0f;

	// If this reaches 0 we kill the player, it should never happen but hey.. you never know. Reason is that we may have been caught in an infinite loop due to unexpected geometry.
	float ElapsedTotal = 0.0f;

	float DistanceCurrent = 0.0f;
	float Mul = 1.0f;
	float PreExitElapsed = 0.0f;

	bool bReturningToVolume = false;
	bool bSoonExit = false;
	bool bWasOutsideOfVolume = false;

	bool bClearSettings = false;
	bool bClearBlockingTags = false;

	bool bCollisionBlocked = false;

	// Only do this in very special cases, when volumes are specifically marked
	bool bPerformSphereTrace = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
		ReturnToVolumeSettings = UMusicFlyingReturnToVolumeSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.ReturnToVolumeSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.LastKnownFlyingVolume == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!FlyingComp.bIsFlying)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.InfiniteFlying())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.bForceActivateReturnToVolume)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if(FlyingComp.CanFly())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.FlyingVolumes > 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		// Setup Spline stuff
		// We Want to have three spline points.
		if(FlyingComp.ReturnToVolumeSpline.Spline.NumberOfSplinePoints != 3)
		{
			FlyingComp.ReturnToVolumeSpline.Spline.ClearSplinePoints(false);
			FlyingComp.ReturnToVolumeSpline.Spline.AddSplinePoint(FVector::ZeroVector, ESplineCoordinateSpace::World, false);
			FlyingComp.ReturnToVolumeSpline.Spline.AddSplinePoint(FVector::ZeroVector, ESplineCoordinateSpace::World, false);
			FlyingComp.ReturnToVolumeSpline.Spline.AddSplinePoint(FVector::ZeroVector, ESplineCoordinateSpace::World, false);
		}

		FVector ExitLocation = FlyingComp.ExitVolumeLocation;

		FHazeHitResult HazeHit;
		FlyingComp.LastKnownFlyingVolume.LineTraceAtComponent(ExitLocation, FlyingComp.LastKnownFlyingVolume.WorldLocation, HazeHit);

		// Lets Build a spline!
		// The center point of the spline is the exit location of the player from the volume.
		FlyingComp.ReturnToVolumeSpline.Spline.SetLocationAtSplinePoint(1, ExitLocation, ESplineCoordinateSpace::World, false);

		float UpDot = HazeHit.ImpactNormal.DotProduct(FVector::UpVector);
		FVector ImpactNormal = HazeHit.ImpactNormal;

		// If we exit the volume flying straight upwards camera and body movement will behave akward when returning, so we need to fix the angle a bit.
		const float DotLimit = 0.7f;
		if(UpDot > DotLimit)
		{
			const float DotDiff = 1.0f - (1.0f - UpDot);
			const float TargetDegrees = FMath::RadiansToDegrees(DotDiff);
			ImpactNormal = ImpactNormal.RotateAngleAxis(TargetDegrees, Player.Mesh.RightVector);
		}
		
		// Let's figure out at what distance we can travel here.

		float DistanceMax = ReturnToVolumeSettings.FlyOutDistanceMax;

		FHitResult Hit;

		TArray<AActor> _ActorsToIgnore = GetActorsToIgnore();

		System::LineTraceSingle(ExitLocation, ExitLocation + ImpactNormal * DistanceMax, ETraceTypeQuery::Visibility, false, _ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

		if(Hit.bBlockingHit)
		{
			DistanceMax = Hit.Distance * 0.85f;
		}

		bool bTriggerExitCamera = true;
		if(DistanceMax < 4000.0f)
		{
			bTriggerExitCamera = false;
		}

		const FVector EndLocation = ExitLocation + ImpactNormal * DistanceMax;
		FlyingComp.ReturnToVolumeSpline.Spline.SetLocationAtSplinePoint(2, EndLocation, ESplineCoordinateSpace::World, false);
		FVector EntryLocation = ExitLocation + (ImpactNormal * -1.0f) * 9000.0f;

		bool bBlockCollision = FlyingComp.LastKnownFlyingVolume.HasTag(n"MusicFlyingReturnBlockCollision");

		if(!bBlockCollision)
			OutParams.AddActionState(n"DoNotBlockCollision");

		
		// Let's try and see if our exit location is still valid.
		Hit.Reset();
		System::LineTraceSingle(ExitLocation, EntryLocation, ETraceTypeQuery::Visibility, false, _ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

		if(Hit.bBlockingHit)
		{
			const FVector DirectionToCenter = (FlyingComp.LastKnownFlyingVolume.WorldLocation - ExitLocation).GetSafeNormal();
			//EntryLocation = ExitLocation + DirectionToCenter * 9000.0f;
		}

		FlyingComp.ReturnToVolumeSpline.Spline.SetLocationAtSplinePoint(0, EntryLocation, ESplineCoordinateSpace::World, false);
		FlyingComp.ReturnToVolumeSpline.Spline.UpdateSpline();

		DistanceCurrent = FlyingComp.ReturnToVolumeSpline.Spline.GetDistanceAlongSplineAtSplinePoint(1) * 1.2f;
		Mul = 1.0f;

		if(!bTriggerExitCamera)
			OutParams.AddActionState(n"NoExitCamera");

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bool bTriggerExitCamera = !ActivationParams.GetActionState(n"NoExitCamera");
		FlyingComp.CurrentBoost = 0.0f;
		FlyingComp.bAlwaysFly = true;
		FlyingComp.bIsReturningToVolume = true;
		ElapsedTotal = 5.0f;
		bClearSettings = false;
		

		bSoonExit = false;
		FlyingComp.bEnableInput = false;

		bool bDoNotBlockCollision = ActivationParams.GetActionState(n"DoNotBlockCollision");

		if(bDoNotBlockCollision)
		{
			bPerformSphereTrace = true;
			bClearBlockingTags = true;
		}
		else
		{
			bClearBlockingTags = false;
			Owner.BlockCapabilities(CapabilityTags::Collision, this);
		}

		Elapsed = ReturnToVolumeSettings.TimeUntilReturning;
		
		bReturningToVolume = false;
		ExitElapsed = ReturnToVolumeSettings.ExitDelay;
		

		if(bTriggerExitCamera)
		{
			if(FlyingComp.ExitVolumeCameraSettings != nullptr)
				Player.ApplyCameraSettings(FlyingComp.ExitVolumeCameraSettings, FHazeCameraBlendSettings(2.5f), this, EHazeCameraPriority::Script);

			if(FlyingComp.ReturnToVolumePhysicsSettings != nullptr)
				Player.ApplySettings(FlyingComp.ReturnToVolumePhysicsSettings, this, EHazeSettingsPriority::Script);

			if(ExitCamera == nullptr)
			{
				ExitCamera = AFollowViewFocusTrackerCamera::Spawn(Player.ViewLocation, Player.ViewRotation);
			}
			else
			{
				ExitCamera.SetActorLocationAndRotation(Player.ViewLocation, Player.ViewRotation);
			}

			ExitCamera.ActivateCamera(Player, CameraBlend::Normal(1.0f), this);
		}

		PreExitElapsed = 0.5f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		const float SplineMovementSpeed = Settings.FlyingSpeedMax * DeltaTime;
		DistanceCurrent = FMath::Clamp(DistanceCurrent + ((SplineMovementSpeed) * Mul), 0.0f, FlyingComp.ReturnToVolumeSpline.Spline.SplineLength);

		if(DistanceCurrent >= FlyingComp.ReturnToVolumeSpline.Spline.SplineLength && !bReturningToVolume)
		{
			bReturningToVolume = true;
			Mul = -1.0f;
		}

		const FVector SplineLoc = FlyingComp.ReturnToVolumeSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceCurrent, ESplineCoordinateSpace::World);
		//System::DrawDebugSphere(SplineLoc, 200.0f, 12, FLinearColor::Green);

		const float DistanceToSplineLocSq = SplineLoc.DistSquared(Owner.ActorLocation);

		const float MaxDist = 1000.0f;
		const float MinDist = 100.0f;
		float DistanceMultiplier = 1.0f;

		if(DistanceToSplineLocSq < FMath::Square(MaxDist))
		{
			DistanceMultiplier = (DistanceToSplineLocSq - FMath::Square(MinDist)) / FMath::Square(MaxDist);
		}

		//PrintToScreen("DistanceMultiplier " + DistanceMultiplier);

		FVector DirToSplineLoc = (SplineLoc - Owner.ActorLocation).GetSafeNormal();

		FVector StartLoc = Owner.ActorLocation;
		FVector EndLoc = StartLoc + DirToSplineLoc * 100.0f;

		if(bPerformSphereTrace)
		{
			TArray<AActor> IgnoreActors;
			IgnoreActors.Add(Game::May);
			IgnoreActors.Add(Game::Cody);
			FHitResult SphereHit;
			System::SphereTraceSingle(StartLoc, EndLoc, 160.0f, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, SphereHit, false);

			if(SphereHit.bBlockingHit)
			{
				const FVector ReflectionVector = FMath::GetReflectionVector(DirToSplineLoc, SphereHit.Normal);
				DirToSplineLoc += (ReflectionVector);
				DirToSplineLoc.Normalize();
			}
		}
		
		FlyingComp.TurnInput = DirToSplineLoc * DistanceMultiplier;
		FlyingComp.InputMovementPlane = DirToSplineLoc * DistanceMultiplier;

		//System::DrawDebugSphere(ExitLocation, 300.0f, 12, FLinearColor::Green);

		if(bSoonExit)
		{
			ExitElapsed -= DeltaTime;
		}
		
		Elapsed -= DeltaTime;

		if(!bSoonExit && FlyingComp.IsInsideFlyingVolume())
		{
			PreExitElapsed -= DeltaTime;
			if(PreExitElapsed < 0.0f)
			{
				FHazeDelegateCrumbParams Params;
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PreReturnToVolume"), Params);
			}
		}

		bWasOutsideOfVolume = !FlyingComp.IsInsideFlyingVolume();

		if(ElapsedTotal < 0.0f && HasControl())
			KillPlayer(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ExitElapsed <= 0.0f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	//	if(bSoonExit && MoveComp.HasAnyBlockingHit())
	//		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION()
	private void Crumb_PreReturnToVolume(FHazeDelegateCrumbData CrumbData)
	{
		ClearSettingsAndCamera();
		ClearBlockingTags();
		bSoonExit = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.bEnableInput = true;
		FlyingComp.bForceActivateReturnToVolume = false;
		Player.ClearSettingsByInstigator(this);

		ClearSettingsAndCamera();
		ClearBlockingTags();
		FlyingComp.bAlwaysFly = false;
		bPerformSphereTrace = false;
		FlyingComp.bIsReturningToVolume = false;
	}

	private TArray<AActor> GetActorsToIgnore() const
	{
		TArray<AActor> Temp;
		Temp.Add(Game::GetCody());

		ACymbal Cymbal = GetCymbalActor();
		Temp.Add(Cymbal);
		Temp.Add(Game::GetMay());
		Temp.Add(FlyingComp.LastKnownFlyingVolume.Owner);
		return Temp;
	}

	private void ClearSettingsAndCamera()
	{
		if(bClearSettings)
			return;

		bClearSettings = true;
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this);
		
		if(ExitCamera != nullptr)
			ExitCamera.DeactivateCamera(Player, 2.0f);
	}

	private void ClearBlockingTags()
	{
		if(bClearBlockingTags)
			return;

		bClearBlockingTags = true;
		Owner.UnblockCapabilities(CapabilityTags::Collision, this);
	}
}
