import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldComponent;

delegate void FParentBlobButtonHoldCompletedDelegate();

UFUNCTION(Category = "ParentBlob")
void BindOnParentBlobButtonHoldCompleted(AActor Actor, FParentBlobButtonHoldCompletedDelegate Delegate)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

    UParentBlobButtonHoldComponent ButtonHoldComp = UParentBlobButtonHoldComponent::GetOrCreate(ParentBlob);
    if (ButtonHoldComp != nullptr)
    {
        ButtonHoldComp.OnButtonHoldCompleted.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
    }
}

UFUNCTION(Category = "ParentBlob")
void StartParentBlobButtonHold(USceneComponent AttachComp)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobButtonHoldComponent ButtonHoldComp = UParentBlobButtonHoldComponent::GetOrCreate(ParentBlob);
	if (ButtonHoldComp == nullptr)
		return;

	ButtonHoldComp.ButtonHoldStarted(AttachComp);
}

UFUNCTION(Category = "ParentBlob")
void StopParentBlobButtonHold()
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobButtonHoldComponent ButtonHoldComp = UParentBlobButtonHoldComponent::GetOrCreate(ParentBlob);
	if (ButtonHoldComp == nullptr)
		return;

	ButtonHoldComp.ButtonHoldStopped();
}

UFUNCTION(Category = "ParentBlob")
void StartParentBlobButtonHoldInteraction(FTransform Transform, USceneComponent AttachComp)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobButtonHoldComponent ButtonHoldComp = UParentBlobButtonHoldComponent::GetOrCreate(ParentBlob);
	if (ButtonHoldComp == nullptr)
		return;

	ButtonHoldComp.ButtonHoldInteractionStarted(Transform, AttachComp);
}

