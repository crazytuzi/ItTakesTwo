import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;

/*
	Communicator component between a key and this actor that wants to have a key.
*/

event void FMusicKeySignature(AHazeActor KeyOwner, AMusicalFollowerKey KeyActor);

void Handle_OnPickedUp(AActor Owner, AMusicalFollowerKey KeyActor)
{
	UMusicKeyComponent KeyComponent = UMusicKeyComponent::Get(Owner);

	if(KeyComponent != nullptr)
	{
		KeyComponent.Handle_OnPickedUp(KeyActor);
	}
}

void Handle_OnLost(AActor Owner, AMusicalFollowerKey KeyActor)
{
	UMusicKeyComponent KeyComponent = UMusicKeyComponent::Get(Owner);

	if(KeyComponent != nullptr)
	{
		KeyComponent.Handle_OnLost(KeyActor);
	}
}

class UMusicKeyComponent : UActorComponent
{
	UPROPERTY()
	FMusicKeySignature OnPickedUp;

	UPROPERTY()
	FMusicKeySignature OnLost;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}
	
	UPROPERTY(Category = Pickup)
	float PickupRange = 2000.0f;

	UPROPERTY()
	bool bLimitMaxKeys = false;

	UPROPERTY(meta = (EditCondition = "bLimitMaxKeys", EditConditionHides))
	int MaxNumKeys = 2;

	// Check if we have reached the maximum number of keys.
	bool CanPickUpKeys() const
	{
		if(!bLimitMaxKeys)
			return true;

		return KeyList.Num() < MaxNumKeys;
	}

	float DisableTimeCurrent = 0.0f;

	AHazeActor HazeOwner;
	// The key that the owner wants to pick up
	AMusicalFollowerKey WantedKey;	

	bool bPickupKeys = true;
	private bool bIsOwnerDisabled = false;

	bool IsOwnerDisabled() const { return bIsOwnerDisabled || DisableTimeCurrent > 0.0f; }

	void SetIsOwnerDisabled(bool bValue)
	{
		bIsOwnerDisabled = bValue;
	}
	
	private TArray<AMusicalFollowerKey> KeyList;

	void GetAllKeys(TArray<AMusicalFollowerKey>& OutKeys) const
	{
		OutKeys = KeyList;
	}

	void SetDisableTime(float InDisableTime)
	{
		if(!HasControl())
			return;

		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(HazeOwner);
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddValue(n"DisableTime", InDisableTime);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetDisableTime"), CrumbParams);
	}

	UFUNCTION()
	void Crumb_SetDisableTime(const FHazeDelegateCrumbData& CrumbData)
	{
		DisableTimeCurrent = CrumbData.GetValue(n"DisableTime");
	}

	bool HasKey() const
	{
		return KeyList.Num() > 0;
	}

	bool HasKey(AMusicalFollowerKey Key) const
	{
		return KeyList.Contains(Key);
	}

	private void AddKey(AMusicalFollowerKey Key)
	{
		KeyList.AddUnique(Key);
	}

	void RemoveKey(AMusicalFollowerKey Key)
	{
		//KeyList.Remove(Key);
	}

	void Handle_OnPickedUp(AMusicalFollowerKey KeyActor)
	{
		KeyList.AddUnique(KeyActor);
		OnPickedUp.Broadcast(HazeOwner, KeyActor);
		KeyActor.OnPickedUp.Broadcast(HazeOwner);
	}

	void Handle_OnLost(AMusicalFollowerKey KeyActor)
	{
		KeyList.Remove(KeyActor);
		OnLost.Broadcast(HazeOwner, KeyActor);
	}

	// Drops the first key
	void DropKey()
	{
		if(KeyList.Num() == 0)
			return;

		AMusicalFollowerKey Key = KeyList[0];
		Key.ClearFollowTarget();
		KeyList.RemoveAt(0);
	}

	void DropAllKeys()
	{
		for(int Index = KeyList.Num() - 1; Index >= 0; --Index)
		{
			AMusicalFollowerKey Key = KeyList[Index];
			Key.ClearFollowTarget();
		}

		KeyList.Reset();
	}

	void DropAllKeys_Local()
	{
		for(int Index = KeyList.Num() - 1; Index >= 0; --Index)
		{
			AMusicalFollowerKey Key = KeyList[Index];
			Key.ClearFollowTarget_Local();
		}

		KeyList.Reset();
	}

	AMusicalFollowerKey GetFirstKey() property
	{
		if(!HasKey())
			return nullptr;

		return KeyList[0];
	}

	int GetKeyIndex(AMusicalFollowerKey KeyActor) const
	{
		for(int Index = 0, Num = KeyList.Num(); Index < Num; ++Index)
		{
			if(KeyActor == KeyList[Index])
				return Index;
		}

		return -1;
	}

	int NumKeys() const
	{
		return KeyList.Num();
	}
}
