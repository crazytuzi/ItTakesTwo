
struct FParentBlobShootingTargetComponentImpactDelegateData
{
	UPROPERTY(BlueprintReadOnly)
	UParentBlobShootingTargetComponent ImpactComponent;

}
event void FParentBlobShootingTargetImpactSignature(FParentBlobShootingTargetComponentImpactDelegateData Data);

UParentBlobShootingTargetComponent GetShootAtTarget()
{
	auto KineticTeam = Cast<UParentBlobShootingTargetTeam>(HazeAIBlueprintHelper::GetTeam(n"ParentBlobShootingTarget"));
	if(KineticTeam == nullptr)
		return nullptr;
	
	if(KineticTeam.Members.Num() == 0)
		return nullptr;

	if(KineticTeam.AvailableComponents.Num() == 0)
		return nullptr;
	
	const int RandomIndex = FMath::RandRange(0, KineticTeam.AvailableComponents.Num() - 1);
	return KineticTeam.AvailableComponents[RandomIndex];
}

void GetAllShootAtTargets(TArray<UParentBlobShootingTargetComponent>& OutTargets)
{
	auto KineticTeam = Cast<UParentBlobShootingTargetTeam>(HazeAIBlueprintHelper::GetTeam(n"ParentBlobShootingTarget"));
	if(KineticTeam == nullptr)
		return;
	
	if(KineticTeam.Members.Num() == 0)
		return;

	if(KineticTeam.AvailableComponents.Num() == 0)
		return;

	OutTargets.Append(KineticTeam.AvailableComponents);
}

class UParentBlobShootingTargetTeam : UHazeAITeam
{
	TArray<UParentBlobShootingTargetComponent> AvailableComponents;
}

class UParentBlobShootingTargetComponent : USceneComponent
{
	UPROPERTY(Category = "Activation")
	bool bBeginAsValidTarget = true;

	UPROPERTY(Category = "Events")
	FParentBlobShootingTargetImpactSignature OnProjectileImpact;

	bool bIsAddedToTeam = false;
	UParentBlobShootingTargetTeam MyTeam;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto HazeOwner = Cast<AHazeActor>(Owner);
		if(HazeOwner != nullptr)
			MakeAvailableAsTarget(bBeginAsValidTarget);	
		else
			devEnsure(false, "ParentBlobShootingTargetComponent is attached to " + Owner.GetName() + " which it not a hazeactor");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		MakeAvailableAsTarget(false);
	}

	UFUNCTION()
	void MakeAvailableAsTarget(bool bStatus)
	{
		if(bIsAddedToTeam == bStatus)
			return;

		bIsAddedToTeam = bStatus;

		auto HazeOwner = Cast<AHazeActor>(Owner);
		if(bIsAddedToTeam)
		{
			MyTeam = Cast<UParentBlobShootingTargetTeam>(HazeOwner.JoinTeam(n"ParentBlobShootingTarget", UParentBlobShootingTargetTeam::StaticClass()));
			MyTeam.AvailableComponents.Add(this);
		}
		else
		{
			MyTeam.AvailableComponents.RemoveSwap(this);
			HazeOwner.LeaveTeam(n"ParentBlobShootingTarget");
			MyTeam = nullptr;
		}
	}
}