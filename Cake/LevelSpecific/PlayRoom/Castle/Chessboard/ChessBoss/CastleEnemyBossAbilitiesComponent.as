import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessBossManager;

UCLASS(Abstract)
class UCastleEnemyBossAbilitiesComponent : UActorComponent
{
	TArray<TSubclassOf<UHazeCapability>> AddedAbilites;

	UPROPERTY(Meta = (AllowAbstract = false))
	TArray<TSubclassOf<UHazeCapability>> BossAbilities;

	TArray<FBossAbility> QueuedAbilities;

	UPROPERTY(EditConst)
	TSubclassOf<UHazeCapability> ActiveAbility;

	UPROPERTY()
	ACastleChessBossManager BossManager;

	UPROPERTY()
	float AbilityCooldown = 3.f;

	UPROPERTY()
	float AbilityCooldownCurrent = AbilityCooldown;

	UChessPieceComponent PieceComp;
	ACastleEnemy OwningChessPiece;
	bool bAbilityFinishedRemoteSide = true;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningChessPiece = Cast<ACastleEnemy>(Owner);

		if (OwningChessPiece == nullptr)
			return;

        PieceComp = UChessPieceComponent::GetOrCreate(Owner);

		for (TSubclassOf<UHazeCapability> Ability : BossAbilities)
		{
			if (!AddedAbilites.Contains(Ability))
			{
				OwningChessPiece.AddCapability(Ability);
				AddedAbilites.Add(Ability);
			}
		}

		// if (BossManager != nullptr)
		// {
		// 	BossManager.OnPhaseChanged.AddUFunction(this, n"OnPhaseChanged");
		// }		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PieceComp.State == EChessPieceState::Fighting)
		{
			ReduceAbilityCooldown(DeltaTime);

			if(CanSelectNewAbility())
				SelectNewAbility();

			// Reset the queued abilities this frame
			QueuedAbilities.Empty();
		}
	}

	UFUNCTION()
	void OnPhaseChanged(int PhaseNumber)
	{

	}

	void ReduceAbilityCooldown(float DeltaTime)
	{
		if (AbilityCooldownCurrent > 0)
			AbilityCooldownCurrent -= DeltaTime;
	}

	bool CanSelectNewAbility()
	{
		if(!HasControl())
			return false;
		if (AbilityCooldownCurrent > 0)
			return false;
		if (ActiveAbility.IsValid())
			return false;
		if (!bAbilityFinishedRemoteSide)
			return false;
		return true;
	}

	void SelectNewAbility()
	{
		if (BossManager == nullptr)
			return;

		if (QueuedAbilities.Num() == 0)
			return;

		FBossAbility NextAbility;
		TArray<FBossAbility> HighPrioBossAbilities;
		TArray<FBossAbility> MedPrioBossAbilities;
		TArray<FBossAbility> LowPrioBossAbilities;

		for (FBossAbility BossAbility : QueuedAbilities)
		{
			if (BossAbility.Priority == EBossAbilityPriority::High)
				HighPrioBossAbilities.Add(BossAbility);
			else if (BossAbility.Priority == EBossAbilityPriority::Medium)
				MedPrioBossAbilities.Add(BossAbility);
			else if (BossAbility.Priority == EBossAbilityPriority::Low)
				LowPrioBossAbilities.Add(BossAbility);
		}

		if (HighPrioBossAbilities.Num() != 0)
		{
			int RandomIndex = FMath::RandRange(0, HighPrioBossAbilities.Num() - 1);
			NextAbility = HighPrioBossAbilities[RandomIndex];

			NetSetActiveAbility(NextAbility);
			RemoveAbilityFromQueue(NextAbility.AbilityType);
			return;		
		}

		if (MedPrioBossAbilities.Num() != 0)
		{
			int RandomIndex = FMath::RandRange(0, MedPrioBossAbilities.Num() - 1);
			NextAbility = MedPrioBossAbilities[RandomIndex];

			NetSetActiveAbility(NextAbility);
			RemoveAbilityFromQueue(NextAbility.AbilityType);
			return;			
		}

		if (LowPrioBossAbilities.Num() != 0)
		{
			int RandomIndex = FMath::RandRange(0, LowPrioBossAbilities.Num() - 1);
			NextAbility = LowPrioBossAbilities[RandomIndex];

			NetSetActiveAbility(NextAbility);
			RemoveAbilityFromQueue(NextAbility.AbilityType);
			return;			
		}
	}

	UFUNCTION(NetFunction)
	void NetSetActiveAbility(FBossAbility NewAbility)
	{
		bAbilityFinishedRemoteSide = false;

		// if (NewAbility.bSyncedAbility)
		// 	BossManager.SyncedAbilities.Add(OwningChessPiece, NewAbility.AbilityType);

		ActiveAbility = NewAbility.AbilityType;
	}

	bool ShouldStartAbility(const UHazeCapability Ability)
	{
		if (PieceComp.bIsMoving)
			return false;

		if (ActiveAbility != Ability.Class)
			return false;

		/* 	A: If the ability is not a synced ability - Start it without waiting
		 	B: If the ability is a synced ability - Start it only if the other piece's is the same ability
		*/
		// TSubclassOf<UHazeCapability> MySyncedAbility;	
		// BossManager.SyncedAbilities.Find(OwningChessPiece, MySyncedAbility);

		// if (MySyncedAbility.IsValid())
		// {			
		// 	// B
		// 	for (auto SyncedAbilityPair : BossManager.SyncedAbilities)
		// 	{
		// 		if (SyncedAbilityPair.Key == OwningChessPiece)
		// 			continue;

		// 		UChessPieceComponent OtherPieceComp = UChessPieceComponent::Get(SyncedAbilityPair.Key);
		// 		if (OtherPieceComp.bIsMoving)
		// 			return false;

		// 		if (MySyncedAbility.Get() == SyncedAbilityPair.Value.Get())
		// 			return true;
		// 	}
			
		// 	return false;
		// }

		// A: Not a synced ability, Start without waiting
		return true;
	}
	
	UFUNCTION()
	void AbilityFinished()
	{
		AbilityCooldownCurrent = AbilityCooldown;
		ActiveAbility = nullptr;

		//BossManager.SyncedAbilities.Remove(OwningChessPiece);

		if (!HasControl() || !Network::IsNetworked())
			NetAbilityRemoteSideFinished();
	}

	UFUNCTION(NetFunction)
	void NetAbilityRemoteSideFinished()
	{
		bAbilityFinishedRemoteSide = true;
	}

	UFUNCTION()
	void AddAbilityToQueue(FBossAbility BossAbility)
	{
		if (QueuedAbilities.Contains(BossAbility))
			return;

		// if (BossAbility.Phase > BossManager.CurrentPhase)
		// 	return;

		QueuedAbilities.Add(BossAbility);
	}

	UFUNCTION()
	void RemoveAbilityFromQueue(UClass Ability)
	{
		for (int Index = 0, Count = QueuedAbilities.Num() - 1; Index < Count; Index++)
		{
			if (QueuedAbilities[Index] == Ability)
			{
				QueuedAbilities.RemoveAt(Index);
				return;
			}
		}
	}
}

struct FBossAbility
{
	UPROPERTY()
	TSubclassOf<UHazeCapability> AbilityType;

	UPROPERTY()	
	bool bSyncedAbility = false;

	UPROPERTY()
	int Phase = 1;

	UPROPERTY()
	EBossAbilityPriority Priority = EBossAbilityPriority::Medium;

	FBossAbility(TSubclassOf<UHazeCapability> InAbilityType, bool InbSyncedAbility = false, int InPhase = 1, EBossAbilityPriority InPriority = EBossAbilityPriority::Medium)
	{
		AbilityType = InAbilityType;
		bSyncedAbility = InbSyncedAbility;
		Phase = InPhase;
		Priority = InPriority;
	}

	bool opEquals(FBossAbility OtherBossAbility)	
	{
		return AbilityType.Get() == OtherBossAbility.AbilityType.Get();
	}

	bool opEquals(TSubclassOf<UHazeCapability> OtherBossAbility)	
	{
		return AbilityType.Get() == AbilityType.Get();
	}

	bool opEquals(UClass OtherBossAbility)	
	{
		return AbilityType.Get() == AbilityType.Get();
	}
}

enum EBossAbilityPriority
{
	High,
	Medium,
	Low
}