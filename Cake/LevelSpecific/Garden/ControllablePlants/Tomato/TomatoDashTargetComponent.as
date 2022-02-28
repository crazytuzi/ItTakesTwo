import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetTeam;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTargetComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoSettings;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoStatics;

event void FOnHitByTomato();

bool IsTomatoDashTargetValid(AHazeActor TargetActor)
{
	if(TargetActor == nullptr)
		return true;

	UTomatoDashTargetComponent DashTargetComp = UTomatoDashTargetComponent::Get(TargetActor);

	if(DashTargetComp != nullptr)
	{
		if(DashTargetComp.bDead)
			return false;

		if(!DashTargetComp.bValidTarget)
			return false;
	}
		

	return true;
}

float GetHitRadius(AHazeActor Target)
{
	if(Target == nullptr)
		return 0;

	UTomatoDashTargetComponent DashTarget = UTomatoDashTargetComponent::Get(Target);

	if(DashTarget != nullptr)
		return DashTarget.HitRadius;

	return 0;
}

/*
	Placed on enemy actors and will act as auto aim target for the tomato / potato etc.
*/

class UTomatoDashTargetComponent : UHazeActivationPoint
{
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default ValidationType = EHazeActivationPointActivatorType::Cody;
	default BiggestDistanceType = EHazeActivationPointDistanceType::Targetable;
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 3000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 1500.f);

	AHazeActor HazeOwner;
	bool bRemovedFromTeam = false;

	UPROPERTY(BlueprintReadWrite)
	bool bValidTarget = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		devEnsure(HazeOwner != nullptr, "Owner is not haze.");
		HazeOwner.JoinTeam(n"TomatoDashTargetTeam", UTomatoDashTargetTeam::StaticClass());

		Owner.OnDestroyed.AddUFunction(this, n"Handle_OnDestroyed");
	}

	UFUNCTION()
	private void Handle_OnDestroyed(AActor DestroyedActor)
	{
		RemoveFromTeam();
	}

	private void RemoveFromTeam()
	{
		if(!bRemovedFromTeam)
		{
			HazeOwner.LeaveTeam(n"TomatoDashTargetTeam");
			bRemovedFromTeam = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveFromTeam();
	}

	UPROPERTY()
	FOnHitByTomato OnHitByTomato;

	UPROPERTY()
	FOnHitByTomato OnHitsTotal;

	// Increase or decrease how much the tomato bounce will behave when hitting this specific target. 1.0 equals to no change.
	UPROPERTY()
	float BounceMultiplier = 1.0f;

	UPROPERTY()
	float HitRadius = 500.0f;

	UPROPERTY()
	bool bBounceOffTarget = true;

	bool bDead = false;

	// Call delegate OnHitsTotal when a Tomato has hit this actor this number of times.
	UPROPERTY()
	int HitsTotal = 1;
	
	int HitsCurrent = 0;

	bool HasReachedTotalHits() const { return HitsCurrent >= HitsTotal; }

	void HandleHitByTomato()
	{
		HitsCurrent += 1;
		OnHitByTomato.Broadcast();

		if(HasReachedTotalHits() && !bDead)
		{
			OnHitsTotal.Broadcast();
			bDead = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	float SetupGetDistanceForPlayer(AHazePlayerCharacter Player, EHazeActivationPointDistanceType Type) const
	{
		UTomatoSettings TomatoSettings = TomatoStatics::GetTomatoSettingsFromPlayer(Player);

		if(TomatoSettings == nullptr)
		{
			return GetDistance(Type);
		}

		if(Type == EHazeActivationPointDistanceType::Selectable)
		{
			return TomatoSettings.DashTargetRange;
		}
		else if(Type == EHazeActivationPointDistanceType::Visible || Type == EHazeActivationPointDistanceType::Targetable)
		{
			return TomatoSettings.DashTargetRange * 1.5f;
		}

		return GetDistance(Type);
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{
		UTomatoTargetComponent TargetComp = UTomatoTargetComponent::Get(Player);

		if(TargetComp == nullptr)
			return EHazeActivationPointStatusType::InvalidAndHidden;
			
		if(TargetComp.IsClosestTarget(Cast<AHazeActor>(Query.Point.Owner)))
			return EHazeActivationPointStatusType::Valid;

		return EHazeActivationPointStatusType::InvalidAndHidden;
	}
}
