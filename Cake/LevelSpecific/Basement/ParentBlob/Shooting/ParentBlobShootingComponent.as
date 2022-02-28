import Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobAmmoContainerActor;
import Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingTargetComponent;

struct FParentBlobShootingDelegateData
{
	UPROPERTY(BlueprintReadOnly)
	AParentBlobShootingProjectile Projectile;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
}
event void FParentBlobShootingSignature(FParentBlobShootingDelegateData Data);

struct FParentBlobShootingImpactDelegateData
{
	UPROPERTY(BlueprintReadOnly)
	AParentBlobShootingProjectile Projectile;

	UPROPERTY(BlueprintReadOnly)
	UParentBlobShootingTargetComponent Target;
}
event void FParentBlobShootingProjectileImpactSignature(FParentBlobShootingImpactDelegateData Data);

void AddAmmoContainer(AParentBlobAmmoContainerActor Container, AParentBlob ParentBlob)
{
	UParentBlobShootingComponent::Get(ParentBlob).AvailableContainers.Add(Container);
}

void RemoveAmmoContainer(AParentBlobAmmoContainerActor Container, AParentBlob ParentBlob)
{
	UParentBlobShootingComponent::Get(ParentBlob).AvailableContainers.RemoveSwap(Container);
}

void TriggerImpactDelegate(AParentBlob ParentBlob, AHazePlayerCharacter ShootingPlayer, AParentBlobShootingProjectile Projectile, UParentBlobShootingTargetComponent Target)
{
	FParentBlobShootingImpactDelegateData Data;
	Data.Projectile = Projectile;
	Data.Target = Target;
	UParentBlobShootingComponent::Get(ParentBlob).OnProjectileImpact.Broadcast(Data);
	if(Target != nullptr)
	{
		FParentBlobShootingTargetComponentImpactDelegateData TargetData;
		TargetData.ImpactComponent = Target;
		Target.OnProjectileImpact.Broadcast(TargetData);
	}
}

class UParentBlobProjetileAttachmentData : UDataAsset
{
    UPROPERTY()
	FName BoneName;

	UPROPERTY()
	FVector Offset;

	UPROPERTY()
	float RotationOffset;

	UPROPERTY()
	FRotator DeltaRotation;
}

class UParentBlobShootingComponent : UActorComponent
{
	default SetTickGroup(ETickingGroup::TG_PostPhysics);
	
	TArray<AParentBlobAmmoContainerActor> AvailableContainers;
	private AParentBlobAmmoContainerActor _CurrentActiveContainer;

	UPROPERTY(Category = "Attachment")
	UParentBlobProjetileAttachmentData LeftAttachment;

	UPROPERTY(Category = "Attachment")
	UParentBlobProjetileAttachmentData RightAttachment;

	UPROPERTY(Category = "Events")
	FParentBlobShootingSignature OnShootProjectile;

	UPROPERTY(Category = "Events")
	FParentBlobShootingProjectileImpactSignature OnProjectileImpact;

	UPROPERTY(BlueprintReadOnly, EditConst, Category = "Attachment")
	bool bMayIsInteractingWithProjetile = false;

	UPROPERTY(BlueprintReadOnly, EditConst, Category = "Attachment")
	bool bCodyIsInteractingWithProjetile = false;
}