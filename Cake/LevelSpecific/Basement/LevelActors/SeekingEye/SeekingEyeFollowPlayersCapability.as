import Cake.LevelSpecific.Basement.LevelActors.SeekingEye.SeekingEye;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class USeekingEyeFollowPlayersCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASeekingEye SeekingEye;

	TArray<AActor> ActorsToIgnore;

	bool bPlayersSpotted = false;

	float ActiveTime = 0.f;
	float TimeUntilPush = 0.2f;

	bool bPushing = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SeekingEye = Cast<ASeekingEye>(Owner);
		ActorsToIgnore.Add(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SeekingEye.bAllowPushback)
			return EHazeNetworkActivation::DontActivate;

		if (PlayersInLineOfSight())
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SeekingEye.bAllowPushback)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!PlayersInLineOfSight())
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveTime = 0.f;
		bPushing = false;
		bPlayersSpotted = true;
		SeekingEye.bFollowingPlayers = true;
		// SeekingEye.ChargeEffect.Activate(true);

		SeekingEye.PlayersSpotted();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bPlayersSpotted = false;
		SeekingEye.bFollowingPlayers = false;
		SeekingEye.bScanningAllowed = false;
		SeekingEye.ChargeEffect.Deactivate();
		SeekingEye.PushEffect.Deactivate();

		SeekingEye.PlayersUnspotted();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		ActiveTime += DeltaTime;

		FVector DirToPlayer = GetActiveParentBlobActor().ActorLocation - SeekingEye.ScanOrigin.WorldLocation;
		DirToPlayer.Normalize();

		FVector ConstrainedDir = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
		FRotator ActorRot = FMath::RInterpConstantTo(Owner.ActorRotation, ConstrainedDir.Rotation(), DeltaTime, 10.f);
		ActorRot.Pitch = Owner.ActorRotation.Pitch;
		ActorRot.Roll = Owner.ActorRotation.Roll;
		// Owner.SetActorRotation(ActorRot);

		if (ActiveTime >= TimeUntilPush)
		{
			EGodMode CurGodMode = GetGodMode(Game::GetMay());
			if (CurGodMode == EGodMode::Mortal)
			{	
				GetActiveParentBlobActor().AddImpulse(ConstrainedDir * 20000.f * DeltaTime);
				StartPushing();
			}
		}
	}

	void StartPushing()
	{
		if (bPushing)
			return;

		// SeekingEye.ChargeEffect.Deactivate();
		bPushing = true;
		SeekingEye.PushEffect.Activate(true);
	}

	bool PlayersInLineOfSight() const
	{
		if (!SeekingEye.bPlayersInCone)
			return false;

		AParentBlob ParentBlob = GetActiveParentBlobActor();		
		FHitResult Hit;
		System::LineTraceSingle(SeekingEye.ScanOrigin.WorldLocation, ParentBlob.ActorLocation + FVector(0.f, 0.f, 100.f), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if (Hit.Actor == ParentBlob)
			return true;

		return false;
	}
}