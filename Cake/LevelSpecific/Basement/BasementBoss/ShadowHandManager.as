import Cake.LevelSpecific.Basement.BasementBoss.ShadowHand;
import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;

event void FOnPlayersKilledByShadowHand(AShadowHand Hand);

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Replication Input Actor LOD Cooking")
class AShadowHandManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY(Category = "Properties")
	TSubclassOf<AShadowHand> ShadowHandClass;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat PostProcessWeightCurve;

	UPROPERTY()
	FOnPlayersKilledByShadowHand OnPlayersKilledByShadowHand;

	UPROPERTY()
	APostProcessVolume TargetPostProcessVolume;

	UPROPERTY()
	ABasementBoss BossActor;

	TArray<AShadowHand> AllShadowHands;

	TArray<AShadowHand> PooledShadowHands;
	TArray<AShadowHand> ActiveShadowHands;

	float DelayBetweenHands = 3.f;

	FTimerHandle SpawnHandTimerHandle;

	bool bPlayersGrabbed = false;

	float CurrentButtonMashProgress = 1.f;

	bool bPlayersKilled = false;

	bool bHandSpawnAllowed = false;

	bool bPlayerGrabbingDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION()
	void DisablePlayerGrabbing()
	{
		bPlayerGrabbingDisabled = true;
	}

	UFUNCTION(DevFunction)
	void StartSpawningHands()
	{
		if (bHandSpawnAllowed)
			return;

		bHandSpawnAllowed = true;

		TArray<AShadowHand> AllHands;
		GetAllActorsOfClass(AllHands);

		SpawnHand();
		StartSpawnTimer();
	}

	UFUNCTION()
	void StopSpawningHands(bool bRemovePrepared = true)
	{
		if (!bHandSpawnAllowed)
			return;

		bHandSpawnAllowed = false;
		System::ClearAndInvalidateTimerHandle(SpawnHandTimerHandle);

		TArray<AShadowHand> AllHands;
		GetAllActorsOfClass(AllHands);
	}

	void StartSpawnTimer()
	{
		if (!bHandSpawnAllowed)
			return;

		SpawnHandTimerHandle = System::SetTimer(this, n"SpawnHand", DelayBetweenHands, true);
	}

	UFUNCTION(NotBlueprintCallable)
	void SpawnHand()
	{
		if (!bHandSpawnAllowed)
			return;

		if (bPlayersKilled)
			return;

		if (bPlayersGrabbed)
			return;

		if (PooledShadowHands.Num() == 0)
		{
			AShadowHand CurrentShadowHand =  Cast<AShadowHand>(SpawnActor(ShadowHandClass, FVector::ZeroVector, FRotator(0.f, 90.f, 0.f)));
			CurrentShadowHand.OnShadowHandDespawned.AddUFunction(this, n"AddShadowHandToPool");
			CurrentShadowHand.OnShadowHandGrabbedPlayers.AddUFunction(this, n"PlayersGrabbed");
			CurrentShadowHand.PrepareShadowHand();
			AllShadowHands.Add(CurrentShadowHand);
			ActiveShadowHands.Add(CurrentShadowHand);
		}
		else
		{
			PooledShadowHands[0].PrepareShadowHand();
			ActiveShadowHands.Add(PooledShadowHands[0]);
			PooledShadowHands.RemoveAt(0);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void AddShadowHandToPool(AShadowHand Hand)
	{
		ActiveShadowHands.Remove(Hand);
		PooledShadowHands.Add(Hand);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersGrabbed(AShadowHand Hand)
	{
		if (!bPlayerGrabbingDisabled)
		{
			StopSpawningHands();
			OnPlayersKilledByShadowHand.Broadcast(Hand);
			KillAndRespawnParentBlob();
		}

		// bPlayersGrabbed = true;
		// System::ClearAndInvalidateTimerHandle(SpawnHandTimerHandle);
		// Hand.OnShadowHandReleasedPlayers.AddUFunction(this, n"PlayersReleased");
		// Hand.OnPlayersKilled.AddUFunction(this, n"PlayersKilled");
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersReleased(AShadowHand Hand)
	{
		bPlayersGrabbed = false;
		StartSpawnTimer();
		CurrentButtonMashProgress = 1.f;
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersKilled(AShadowHand Hand)
	{
		if (bPlayersKilled)
			return;

		bPlayersKilled = true;
		OnPlayersKilledByShadowHand.Broadcast(Hand);
	}

	void UpdateButtonMashProgress(float Progress)
	{
		CurrentButtonMashProgress = Progress;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bPlayersKilled)
			return;

		if (TargetPostProcessVolume != nullptr)
		{
			if (bPlayersGrabbed)
			{
				float WeightAlpha = PostProcessWeightCurve.GetFloatValue(CurrentButtonMashProgress);
				float Weight = FMath::Lerp(1.f, 0.f, WeightAlpha);
				PrintToScreen("" + Weight);
				TargetPostProcessVolume.BlendWeight = Weight;
			}
			else
			{
				TargetPostProcessVolume.BlendWeight = 0.f;
			}
		}
	}
}