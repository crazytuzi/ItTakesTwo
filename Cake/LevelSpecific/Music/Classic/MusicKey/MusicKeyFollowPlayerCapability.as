import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;
import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;

class UMusicKeyFollowPlayerCapability : UHazeCapability
{
	FHazeAcceleratedVector AcceleratedLocation;
	UMusicKeyComponent PlayerKeyComp;
	AMusicalFollowerKey Key;
	FVector RotationOffset;

	float Elapsed = 0.0f;

	bool bWasMoving = false;

	float RandomOffset = 0.0f;

	TArray<AKeyBirdCombatArea> CombatAreaCollection;

	float HeightOffset = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Key = Cast<AMusicalFollowerKey>(Owner);

		TArray<AActor> ListOfAreas;
		Gameplay::GetAllActorsOfClass(AKeyBirdCombatArea::StaticClass(), ListOfAreas);

		for(AActor Area : ListOfAreas)
		{
			AKeyBirdCombatArea CombatArea = Cast<AKeyBirdCombatArea>(CombatArea);

			if(CombatArea != nullptr)
				CombatAreaCollection.Add(CombatArea);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Key.FollowTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Key.MusicKeyState != EMusicalKeyState::FollowTarget)
			return EHazeNetworkActivation::DontActivate;

		if(!Key.FollowTarget.IsA(AHazePlayerCharacter::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedLocation.Value = Owner.ActorLocation;
		PlayerKeyComp = UMusicKeyComponent::Get(Key.FollowTarget);
		Key.SetGlowActive(false);
		Key.SetTrailActive(true, false);
		RandomOffset = FMath::RandRange(0.0f, 10000.0f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Offset = 0;

		if(PlayerKeyComp != nullptr)
		{
			const int NumKeys = FMath::Max(PlayerKeyComp.NumKeys(), 1);
			const int ThisIndex = PlayerKeyComp.GetKeyIndex(Key);
			const int Radius = 360;
			const int OffsetChunkSize = 360 / NumKeys;
			Offset += (float(OffsetChunkSize) * float(ThisIndex));
		}

		Elapsed += Key.RotationSpeed * DeltaTime;
		FVector DirectionToKey = (Owner.ActorCenterLocation - Key.FollowTarget.ActorCenterLocation).GetSafeNormal();
		float GameTimeInSeconds = float(System::GameTimeInSeconds);
		
		FQuat RotOffset = FQuat(FVector::UpVector, GameTimeInSeconds + FMath::DegreesToRadians(Offset));
		DirectionToKey += RotOffset.Vector();
		DirectionToKey.Normalize();

		FVector TargetLocation = Key.FollowTarget.ActorCenterLocation + DirectionToKey * Key.PlayerOffsetDistance;
		AcceleratedLocation.AccelerateTo(TargetLocation, 0.6f, DeltaTime);

		Owner.AddActorWorldRotation(FRotator(0, Key.LocalRotationSpeed * DeltaTime, 0));

		
		HeightOffset = ((FMath::MakePulsatingValue(GameTimeInSeconds + Offset, Key.UpDownSpeed) * 2.0f) - 1.0f) * Key.UpDownLength;

		Owner.SetActorLocation(AcceleratedLocation.Value + FVector(0, 0, HeightOffset));

		

		if(HasControl())
		{
			for(AKeyBirdCombatArea CombatArea : CombatAreaCollection)
			{
				if(CombatArea.IsInsideCombatArea(Key.FollowTarget.ActorLocation) && Key.CombatArea != CombatArea)
				{
					NetChangeBoidArea(CombatArea);
					break;
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetChangeBoidArea(AKeyBirdCombatArea NewCombatArea)
	{
		Key.CombatArea = NewCombatArea;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Key.FollowTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Key.MusicKeyState != EMusicalKeyState::FollowTarget)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!Key.FollowTarget.IsA(AHazePlayerCharacter::StaticClass()))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
