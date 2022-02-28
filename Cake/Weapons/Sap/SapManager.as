import Cake.Weapons.Sap.SapWeaponAimStatics;
import Cake.Weapons.Sap.SapWeaponSettings;
import Cake.Weapons.Sap.SapCustomAttachComponent;
import Cake.Weapons.Sap.SapBatch;
import Cake.Weapons.Sap.SapLog;

const FStatID STAT_SapBatchFindLocation(n"SapBatchFindLocation");
const FStatID STAT_SapBatchFindAttached(n"SapBatchFindAttached");

event void FOnSapManagerFirstExplodeEvent();
event void FOnSapManagerFirstHugeExplodeEvent();
event void FOnSapManagerHitNonStickEvent(USceneComponent HitComp);

// Returns what happens when requesting to spawn sap somewhere
enum ESapSpawnResult
{
	Invalid,
	Spawned,
	MassAdded,
	NonStick,
	Consumed
}

struct FSapWeight
{
	UPROPERTY()
	FVector CenterOfMass;

	UPROPERTY()
	float TotalMass;
}

struct FSapIgnition
{
	FSapIgnition(uint8 InIndex, uint8 InMass, float InDelay)
	{
		Index = InIndex;
		Mass = InMass;
		Delay = InDelay;
	}
	uint8 Index;
	uint8 Mass;
	float Delay;
}

// Component containing the current worlds instance of the sap manager.
// Should be on cody.
class USapManagerSingletonComponent : UActorComponent
{
	USapManager Manager;
}

// Global functions called from the sap batches and sap response component
USapManager GetSapManager()
{
	auto Singleton = USapManagerSingletonComponent::Get(Game::GetCody());

	if (Singleton == nullptr)
		return nullptr;

	return Singleton.Manager;
}

void SetSapManager(USapManager Manager)
{
	auto Singleton = USapManagerSingletonComponent::GetOrCreate(Game::GetCody());
	ensure(Singleton.Manager == nullptr);

	Singleton.Manager = Manager;
}

// This is used to limit how many saps can explode per frame
//		to avoid hitching
bool SapCanExplodeThisFrame()
{
	auto Manager = GetSapManager();
	if (Manager == nullptr)
		return false;

	return Manager.LastExplodeFrame != GFrameNumber;
}

UFUNCTION(Category="Sap")
void SapTriggerExplosionAtPoint(FVector WorldLocation, float Radius)
{
	auto Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	Manager.LastExplodeFrame = GFrameNumber;

	if (!Manager.CanDestroySaps())
		return;

	TArray<FSapIgnition> Ignitions;
	Manager.GetBatchesToBeIgnitedFrom(WorldLocation, Radius, Ignitions);

	if (Ignitions.Num() > 0)
		Manager.NetIgniteBatches(Ignitions);
}

UFUNCTION(Category="Sap")
void ExplodeAllSapsAttachedTo(USceneComponent Root)
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	if (!Manager.CanDestroySaps())
		return;

	TArray<ASapBatch> Batches = Manager.FindBatchesAttachedTo(Root);
	TArray<FSapIgnition> Ignitions;
	Ignitions.Reserve(Batches.Num());

	for(auto Batch : Batches)
		Ignitions.Add(FSapIgnition(Batch.Index, Batch.Mass, 0.f));

	Manager.NetIgniteBatches(Ignitions);
}

UFUNCTION(Category="Sap")
void DisableAllSapsAttachedTo(USceneComponent Root)
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	if (!Manager.CanDestroySaps())
		return;

	TArray<ASapBatch> Batches = Manager.FindBatchesAttachedTo(Root);

	TArray<int> Indicies;
	Indicies.Reserve(Batches.Num());

	for(auto Batch : Batches)
		Indicies.Add(Batch.Index);

	Manager.NetDisableBatches(Indicies);
}

UFUNCTION(Category="Sap")
void DisableSwarmSapByIndex(int Index)
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	if (!Manager.CanDestroySaps())
		return;

	Manager.NetDisableBatch(Index);
}

// Returns amount of mass successfully removed
UFUNCTION(Category="Sap")
float RemoveSapMassFrom(USceneComponent Root, float InMassToRemove)
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return 0.f;

	if (!Manager.CanDestroySaps())
		return 0.f;

	TArray<ASapBatch> Batches = Manager.FindBatchesAttachedTo(Root);
	float MassToRemove = InMassToRemove;

	for(auto Batch : Batches)
	{
		MassToRemove -= Manager.RemoveMassFromBatch(Batch, MassToRemove);
		if (FMath::IsNearlyZero(MassToRemove))
			break;
	}

	return InMassToRemove - MassToRemove;
}

// Returns amount of mass successfully removed
UFUNCTION(Category="Sap")
float RemoveSapMassNear(FVector WorldLocation, float Radius, float InMassToRemove)
{
	auto Manager = GetSapManager();
	if (Manager == nullptr)
		return 0.f;

	TArray<ASapBatch> Batches = Manager.FindBatchesAtLocation(WorldLocation, Radius);

	float MassToRemove = InMassToRemove;
	for(auto Batch : Batches)
	{
		MassToRemove -= Manager.RemoveMassFromBatch(Batch, MassToRemove);
		if (FMath::IsNearlyZero(MassToRemove))
			break;
	}

	return InMassToRemove - MassToRemove;
}

UFUNCTION(Category="Sap")
FSapWeight SapGetTotalAttachedWeight(USceneComponent Root)
{
	auto Manager = GetSapManager();
	if (Manager == nullptr)
		return FSapWeight();

	FSapWeight Result;
	Result.CenterOfMass = FVector::ZeroVector;
	Result.TotalMass = 0.f;

	TArray<ASapBatch> AttachedSaps = Manager.FindBatchesAttachedTo(Root);
	if (AttachedSaps.Num() == 0)
		return Result;

	FTransform RootTransform = Root.WorldTransform;

	for(ASapBatch Batch : AttachedSaps)
	{
		FVector WorldLocation = Batch.Target.WorldLocation;
		FVector RelativeLocation = RootTransform.InverseTransformPosition(WorldLocation);

		Result.CenterOfMass += RelativeLocation * Batch.Mass;
		Result.TotalMass += Batch.Mass;
	}

	// Center of mass will be weighted sum, so average over the total mass
	if (!FMath::IsNearlyZero(Result.TotalMass))
		Result.CenterOfMass /= Result.TotalMass;

	return Result;
}

UFUNCTION(Category="Sap")
void HideAllSapsAttachedTo(USceneComponent Root)
{
	auto Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	TArray<ASapBatch> Batches = Manager.FindBatchesAttachedTo(Root);
	for(auto Batch : Batches)
	{
		Batch.HideBatch(n"HideAttached");
	}
}

UFUNCTION(Category="Sap")
void ShowAllSapsAttachedTo(USceneComponent Root)
{
	auto Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	TArray<ASapBatch> Batches = Manager.FindBatchesAttachedTo(Root);
	for(auto Batch : Batches)
	{
		Batch.ShowBatch(n"HideAttached");
	}
}

UFUNCTION(Category="Sap")
bool GetSapIsLocatedNear(FVector Location, float Radius)
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return false;

	return Manager.FindBatchAtLocation(Location, Radius) != nullptr;
}

UFUNCTION(Category="Sap")
void HideAllSaps()
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	for(auto Batch : Manager.BatchPool)
	{
		Batch.HideBatch(n"HideAll");
	}
}

UFUNCTION(Category="Sap")
void ShowAllSaps()
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	for(auto Batch : Manager.BatchPool)
	{
		Batch.ShowBatch(n"HideAll");
	}
}

UFUNCTION(Category="Sap")
void DisableAllSaps()
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	if (!Manager.CanDestroySaps())
		return;

	TArray<int> Indicies;
	for(auto Batch : Manager.BatchPool)
	{
		if (Batch.bIsEnabled)
			Indicies.Add(Batch.Index);
	}

	Manager.NetDisableBatches(Indicies);
}

void ExplodeSap(ASapBatch Batch)
{
	USapManager Manager = GetSapManager();
	if (Manager == nullptr)
		return;

	// May is in charge of this..
	if (!Manager.CanDestroySaps())
		return;

	Manager.NetExplodeBatch(Batch.Index, Batch.Mass);
}

class USapManager : UObjectInWorld
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASapBatch> BatchClass;
	TArray<ASapBatch> BatchPool;

	TArray<ASapBatch> LitBatches;

	uint32 LastExplodeFrame = 0;

	bool CanCreateSaps()
	{
		return Game::Cody.HasControl();
	}

	bool CanDestroySaps()
	{
		return Game::May.HasControl();
	}

	void Init()
	{
		SetSapManager(this);

		for(int i=0; i<Sap::Batch::NumBatches; ++i)
		{
			ASapBatch Batch = Cast<ASapBatch>(SpawnActor(BatchClass));
			Batch.MakeNetworked(this, i);

			Batch.Init(i);
			BatchPool.Add(Batch);
		}
	}

	int CalculateNumAvailableSaps()
	{
		int Num = 0;
		for(int i=0; i<Sap::Batch::NumBatches; ++i)
		{
			if (!BatchPool[i].bIsEnabled)
				Num++;
		}

		return Num;
	}

	ASapBatch FindBatchAtLocation(FVector WorldLocation, float SearchRadius, ASapBatch Ignore = nullptr)
	{
		for(ASapBatch Batch : BatchPool)
		{
			if (!Batch.bIsEnabled)
				continue;

			if (Batch == Ignore)
				continue;

			float DistanceSqrd = WorldLocation.DistSquared(Batch.Target.WorldLocation);
			float RadSqrd = FMath::Square(SearchRadius + Batch.GetBatchSize() * Sap::Radius);

			if (DistanceSqrd <= RadSqrd)
				return Batch;
		}

		return nullptr;
	}

	ASapBatch FindBatchCenterAtTarget(FSapAttachTarget Target, float SearchRadius = 0.f, ASapBatch Ignore = nullptr)
	{
		for(ASapBatch Batch : BatchPool)
		{
			if (!Batch.bIsEnabled)
				continue;

			if (Batch == Ignore)
				continue;

			if (!Target.CanReach(Batch.Target))
				continue;

			float DistanceSqrd = Target.DistSquared(Batch.Target);
			float RadSqrd = FMath::Square(SearchRadius);

			if (DistanceSqrd <= RadSqrd)
				return Batch;
		}

		return nullptr;
	}

	ASapBatch FindBatchAtTarget(FSapAttachTarget Target, float SearchRadius = 0.f, ASapBatch Ignore = nullptr)
	{
		for(ASapBatch Batch : BatchPool)
		{
			if (!Batch.bIsEnabled)
				continue;

			if (Batch == Ignore)
				continue;

			if (!Target.CanReach(Batch.Target))
				continue;

			float DistanceSqrd = Target.DistSquared(Batch.Target);
			float RadSqrd = FMath::Square(SearchRadius + Batch.GetBatchSize() * Sap::Radius);

			if (DistanceSqrd <= RadSqrd)
				return Batch;
		}

		return nullptr;
	}

	TArray<ASapBatch> FindBatchesAtLocation(FVector WorldLocation, float SearchRadius)
	{
#if TEST
		FScopeCycleCounter EntryCounter(STAT_SapBatchFindLocation);
#endif

		TArray<ASapBatch> Batches;
		for(ASapBatch Batch : BatchPool)
		{
			if (!Batch.bIsEnabled)
				continue;

			float DistanceSqrd = WorldLocation.DistSquared(Batch.Target.WorldLocation);
			float RadSqrd = FMath::Square(SearchRadius + Batch.GetBatchSize() * Sap::Radius);

			if (DistanceSqrd <= RadSqrd)
				Batches.Add(Batch);
		}

		return Batches;
	}

	TArray<ASapBatch> FindBatchesAttachedTo(USceneComponent Root)
	{
#if TEST
		FScopeCycleCounter EntryCounter(STAT_SapBatchFindAttached);
#endif

		TArray<ASapBatch> Batches;

		auto Manager = GetSapManager();
		if (Manager == nullptr)
			return Batches;

		for(ASapBatch Batch : Manager.BatchPool)
		{
			if (!Batch.bIsEnabled)
				continue;

			USceneComponent AttachComp = Batch.Target.Component;
			if (AttachComp == nullptr)
				continue;

			if (AttachComp == Root || AttachComp.IsAttachedTo(Root))
			{
				Batches.Add(Batch);
			}
		}

		return Batches;
	}

	void AddMassToBatch(ASapBatch Batch, float Mass)
	{
		if (!CanCreateSaps())
			return;

		NetAddMassToBatch(Batch.Index, Mass);
	}

	// Return mass removed
	float RemoveMassFromBatch(ASapBatch Batch, float MassToRemove)
	{
		if (!CanDestroySaps())
			return 0.f;

		float MassDelta = FMath::Min(MassToRemove, Batch.Mass);
		NetRemoveMassFromBatch(Batch.Index, MassDelta);

		if (Batch.Mass < Sap::Batch::MinMass)
			NetDisableBatch(Batch.Index);

		return MassDelta;
	}

	ASapBatch FindBestRecyclableBatch()
	{
		// We split the batches into those attached to response objects, and those who aren't
		// 	so that we recycle non-response batches first! Then, if none are available, we start recycling
		//	response batches anyways.
		float OldestTime = 0.f;
		ASapBatch OldestBatch = nullptr;
		float OldestResponseTime = 0.f;
		ASapBatch OldestResponseBatch = nullptr;

		for(auto Batch : BatchPool)
		{
			if (!Batch.bIsEnabled)
				continue;

			// Reponse batch...
			if (Batch.ResponseComp != nullptr)
			{
				if (Batch.EnableTime < OldestResponseTime || OldestResponseBatch == nullptr)
				{
					OldestResponseTime = Batch.EnableTime;
					OldestResponseBatch = Batch;
				}
			}
			// Non-response batch...
			else
			{
				if (Batch.EnableTime < OldestTime || OldestBatch == nullptr)
				{
					OldestTime = Batch.EnableTime;
					OldestBatch = Batch;
				}
			}
		}

		if (OldestBatch != nullptr)
			return OldestBatch;
		else
			return OldestResponseBatch;
	}

	ESapSpawnResult SpawnSapAtTarget(FSapAttachTarget InTarget, float Mass)
	{
		// Because it might change...
		FSapAttachTarget Target = InTarget;

		// Tries to spawn a sap at a particular location and returns the result
		// However, on the non-creator side, the result of the spawning is just predicted, nothing is actually changed!

		// Consuming means the response component completely handles what happens when a sap hits, and nothing should be spawned
		// (ovens, traps in beetle fight, etc.)
		if (Target.Component.HasTag(n"TreeProjectileConsume"))
		{
			if (CanCreateSaps())
				NetHitConsumed(Target, Mass);

			return ESapSpawnResult::Consumed;
		}

		// Non-stickable surface
		if (!Target.Component.HasTag(n"SapStickable"))
		{
			if (CanCreateSaps())
				NetHitNonStickable(Target, Mass);

			return ESapSpawnResult::NonStick;
		}

		if (Target.Actor != nullptr)
		{
			// If we get this far, its time to check if theres a custom attach point
			auto CustomAttach = USapCustomAttachComponent::Get(Target.Actor);
			if (CustomAttach != nullptr)
			{
				Target = FSapAttachTarget();
				Target.Component = CustomAttach;
			}
		}

		ASapBatch Batch = nullptr;

		// First see if we should just increase the Mass of already existing batches
		Batch = FindBatchAtTarget(Target, Sap::Radius);
		if (Batch != nullptr)
		{
			if (CanCreateSaps())
				AddMassToBatch(Batch, Mass);

			return ESapSpawnResult::MassAdded;
		}
		else
		{
			// No merge, create a whole new batch!
			for(int i=0; i<BatchPool.Num(); ++i)
			{
				if (!BatchPool[i].bIsEnabled)
				{
					Batch = BatchPool[i];
					break;
				}
			}

			// Uh oh! Our available sap buffer ran out :( Network must've lagged a lot, or I fucked up
			// If you're reading this, let Emil know <3
			if (!ensure(Batch != nullptr))
				return ESapSpawnResult::Invalid;

			if (CanCreateSaps())
				NetCreateBatch(Batch.Index, Target, Mass);

			return ESapSpawnResult::Spawned;
		}
	}

	UFUNCTION(NetFunction)
	void NetCreateBatch(int Index, FSapAttachTarget Target, float Mass)
	{
		auto Batch = BatchPool[Index];

		// Uh oh! On the Destroyers side, this target is invalid.. This probably means
		// 	whatever the Creator shot at is destroyed on our side. Invalidate this sap.
		if (!Target.HasAttachParent() && CanDestroySaps())
		{
			NetInvalidateBatch(Index);
			return;
		}

		Batch.EnableBatch(Target, Mass);
		LightUpBatch(Batch);

		// The Destroyer is the only one who can, well, destroy stuff
		// So the Destroyer side is the one that has to make sure the Creator side always
		// has some available saps to create, so we make sure to always keep a small buffer of disabled saps
		if (CanDestroySaps())
		{
			int SapsToDisable = Sap::Batch::MinAvailableBatches - CalculateNumAvailableSaps();

			FString Prefix;
			if (Network::IsNetworked())
			{
				Prefix = Network::GetNetworkPrefix();
				if (Prefix.Len() != 0)
				{
					Prefix += " ";
				}
			}

			for(int i=0; i<SapsToDisable; ++i)
			{
				auto RecycleBatch = FindBestRecyclableBatch();
				SapLog("SAPMANAGER Recycle [" + RecycleBatch.Index + "\t]");

				NetDisableBatch(RecycleBatch.Index);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetInvalidateBatch(int Index)
	{
		// This is only called when NetCreateBatch fails on Destroyers side, which means the sap
		// was never created. So only run this code on the Creators side.
		if (CanDestroySaps())
			return;

		auto Batch = BatchPool[Index];
		Batch.DisableBatch();
	}

	UFUNCTION(NetFunction)
	void NetDisableBatch(int Index)
	{
		SapLog("SAPMANAGER NetDisableBatch[" + Index + "\t]");

		auto Batch = BatchPool[Index];

		// This batch is on the bring of explosion, so just wait until it does so
		// Otherwise, it might have exploded on the other side already, causing desyncs
		if (Batch.bWantsToExplode || Batch.bIsIgnited)
		{
			SapLog("SAPMANAGER SkipBatch[" + Index + "\t]");
			return;
		}

		Batch.DisableBatch();
	}

	UFUNCTION(NetFunction)
	void NetDisableBatches(TArray<int> Indicies)
	{
		for(auto Index : Indicies)
		{
			SapLog("SAPMANAGER NetDisableBatch[" + Index + "\t]");
			auto Batch = BatchPool[Index];

			// This batch is on the bring of explosion, so just wait until it does so
			// Otherwise, it might have exploded on the other side already, causing desyncs
			if (Batch.bWantsToExplode || Batch.bIsIgnited)
			{
				SapLog("SAPMANAGER SkipBatch[" + Index + "\t]");
				continue;
			}

			Batch.DisableBatch();
		}
	}

	UFUNCTION(NetFunction)
	void NetAddMassToBatch(int Index, float MassToAdd)
	{
		ASapBatch Batch = BatchPool[Index];
		Batch.GainMass(MassToAdd);

		LightUpBatch(Batch);
	}

	UFUNCTION(NetFunction)
	void NetRemoveMassFromBatch(int Index, float MassToRemove)
	{
		ASapBatch Batch = BatchPool[Index];
		Batch.RemoveMass(MassToRemove);
	}

	UFUNCTION(NetFunction)
	void NetIgniteBatches(TArray<FSapIgnition> Ignitions)
	{
#if TEST
		FString SapsString = "";
		for(auto Ignition : Ignitions)
			SapsString += "" + Ignition.Index + "(" + Ignition.Delay + "), ";

		SapLog("SAPMANAGER IgniteBatches[" + SapsString + "]");
#endif

		for(auto Ignition : Ignitions)
		{
			auto Batch = BatchPool[Ignition.Index];
			Batch.SetNewMass(Ignition.Mass);
			Batch.Ignite(Ignition.Delay);
		}
	}

	UFUNCTION(NetFunction)
	void NetHitNonStickable(FSapAttachTarget Where, float Mass)
	{
		if (System::IsValid(Where.Actor))
		{
			auto ResponseComp = USapResponseComponent::Get(Where.Actor);
			if (ResponseComp == nullptr)
				return;

			ResponseComp.OnHitNonStick.Broadcast(Where, Mass);
		}
	}

	UFUNCTION(NetFunction)
	void NetHitConsumed(FSapAttachTarget Where, float Mass)
	{
		if (System::IsValid(Where.Actor))
		{
			auto ResponseComp = USapResponseComponent::Get(Where.Actor);
			if (ResponseComp == nullptr)
				return;

			ResponseComp.OnSapConsumed.Broadcast(Where, Mass);
		}
	}

	UFUNCTION(NetFunction)
	void NetExplodeBatch(int Index, float ExplodeMass)
	{
		auto Batch = BatchPool[Index];

		// Just set the mass for now >_>
		Batch.SetNewMass(ExplodeMass);
		Batch.RequestExplosion();
	}

	void LightUpBatch(ASapBatch Batch)
	{
		Batch.FadeUpLight();

		if (LitBatches.Contains(Batch))
		{
			// If this is already lit, move it to the front of the list
			LitBatches.Remove(Batch);
			LitBatches.Add(Batch);
		}
		else
		{
			// Otherwise, add it to the end and light it up!
			LitBatches.Add(Batch);

			if (LitBatches.Num() > Sap::Batch::MaxPointLights)
			{
				// Too many lights, fade down the first one
				ASapBatch FirstBatch = LitBatches[0];
				LitBatches.RemoveAt(0);
				FirstBatch.FadeDownLight();
			}
		}
	}

	void GetBatchesToBeIgnitedFrom(FVector Source, float Radius, TArray<FSapIgnition>& OutIgnitions)
	{
		TArray<ASapBatch> AffectedBatches = FindBatchesAtLocation(Source, Radius);
		for(auto Batch : AffectedBatches)
		{
			if (Batch.bHasExploded || Batch.bIsIgnited)
				continue;

			float Dist = Batch.ActorLocation.Distance(Source) - Batch.GetBatchSize();
			float DistPercent = Math::Saturate(Dist / Radius);
			float IgniteDelay = FMath::Lerp(Sap::Explode::MinDelay, Sap::Explode::MaxDelay, DistPercent);

			OutIgnitions.Add(FSapIgnition(Batch.Index, Batch.Mass, IgniteDelay));
		}
	}
}