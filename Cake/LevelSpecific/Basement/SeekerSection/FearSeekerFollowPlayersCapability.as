import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.SeekerSection.FearSeeker;

class UFearSeekerFollowPlayersCapability : UHazeCapability
{
	/*default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AFearSeeker FearSeeker;
	USceneComponent ScanOrigin;

	TArray<AActor> ActorsToIgnore;

	bool bPlayersInLineOfSight = false;
	bool bHasBrokenLineOfSight = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FearSeeker = Cast<AFearSeeker>(Owner);
		ScanOrigin = FearSeeker.SearchRoot;
		ActorsToIgnore.Add(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AParentBlob ParentBlob = GetActiveParentBlobActor();
		if (ParentBlob == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (GetDistanceToPlayers(ParentBlob) >= FearSeeker.MaxRange)
			return EHazeNetworkActivation::DontActivate;

		if (!bPlayersInLineOfSight)
        	return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		AParentBlob ParentBlob = GetActiveParentBlobActor();
		if (ParentBlob == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (GetDistanceToPlayers(ParentBlob) >= FearSeeker.MaxRange)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!bPlayersInLineOfSight)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FearSeeker.bPlayerSpotted = true;
		bHasBrokenLineOfSight = false;
		bPlayersInLineOfSight = true;
		
		FearSeeker.OnSpottedByFearSeeker.Broadcast(FearSeeker.DamageSpeed);

		// FearSeeker.BeamComp.SetHiddenInGame(false);
		// FearSeeker.BeamComp.Activate(true);

		Game::GetMay().PlayCameraShake(FearSeeker.SpottedCamShake);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayForceFeedback(FearSeeker.SpottedRumble, true, true, n"Spotted");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FearSeeker.bPlayerSpotted = false;
		bHasBrokenLineOfSight = true;
		bPlayersInLineOfSight = false;

		FearSeeker.OnUnspottedByFearSeeker.Broadcast();

		// FearSeeker.BeamComp.Deactivate();
		// FearSeeker.BeamComp.SetHiddenInGame(true);

		Game::GetMay().StopAllInstancesOfCameraShake(FearSeeker.SpottedCamShake, false);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopForceFeedback(FearSeeker.SpottedRumble, n"Spotted");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		AParentBlob ParentBlob = GetActiveParentBlobActor();
		if (ParentBlob == nullptr)
			return;
			
		FVector PlayerLocation = ParentBlob.ActorLocation + FVector(0.f, 0.f, 135.f);
		FVector DirToPlayer = PlayerLocation - ScanOrigin.WorldLocation;
		DirToPlayer = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
		DirToPlayer = DirToPlayer.GetSafeNormal();
		float DotToPlayer = DirToPlayer.DotProduct(FearSeeker.SearchRoot.ForwardVector);

		if (bHasBrokenLineOfSight)
		{
			if (FearSeeker.bTrackPlayersUsingSideOffset)
			{
				FVector Dif = FearSeeker.ActorLocation.X - ParentBlob.ActorLocation.X;
				float DifSize = FMath::Abs(Dif.Size());
				
				if (DifSize >= 2000.f || DotToPlayer <= 0.65f)
				{
					bPlayersInLineOfSight = false;
					return;
				}
			}
			else
			{
				if (DotToPlayer <= 0.8f)
				{
					bPlayersInLineOfSight = false;
					return;
				}
			}
		}

		FHitResult Hit;
		System::LineTraceSingle(ScanOrigin.WorldLocation, PlayerLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
		if (Hit.bBlockingHit)
		{
			if (Hit.Actor == nullptr)
			{
				bPlayersInLineOfSight = false;
				bHasBrokenLineOfSight = true;
				return;
			}
			if (Hit.Actor == ParentBlob)
			{
				bPlayersInLineOfSight = true;
				bHasBrokenLineOfSight = false;
				return;
			}
		}

		bPlayersInLineOfSight = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// FearSeeker.BeamComp.SetVectorParameter(n"User.BeamStart", FearSeeker.SearchRoot.WorldLocation);
		// FearSeeker.BeamComp.SetVectorParameter(n"User.BeamEnd", GetActiveParentBlobActor().ActorLocation + FVector(0.f, 0.f, 100.f));

		if (!FearSeeker.bRotateTowardsPlayers)
			return;

		AParentBlob ParentBlob = GetActiveParentBlobActor();
		FVector DirToPlayer = ParentBlob.ActorLocation - ScanOrigin.WorldLocation;
		DirToPlayer.Normalize();

		FVector ConstrainedDir = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
		FRotator ActorRot = FMath::RInterpConstantTo(Owner.ActorRotation, ConstrainedDir.Rotation(), DeltaTime, 10.f);
		ActorRot.Pitch = Owner.ActorRotation.Pitch;
		ActorRot.Roll = Owner.ActorRotation.Roll;
		
		FVector RootDirToPlayer = ParentBlob.ActorLocation - FearSeeker.ActorLocation;
		RootDirToPlayer = Math::ConstrainVectorToPlane(RootDirToPlayer, FVector::UpVector);
		RootDirToPlayer = RootDirToPlayer.GetSafeNormal();

		FRotator DesiredRot = FMath::RInterpTo(FearSeeker.ActorRotation, RootDirToPlayer.Rotation(), DeltaTime, 3.f);
		DesiredRot.Roll = FearSeeker.ActorRotation.Roll;
		DesiredRot.Pitch = FearSeeker.ActorRotation.Pitch;

		FearSeeker.SetActorRotation(DesiredRot);
	}

	float GetDistanceToPlayers(AParentBlob ParentBlob) const
	{
		return (ParentBlob.ActorLocation - ScanOrigin.WorldLocation).Size();
	}*/
}