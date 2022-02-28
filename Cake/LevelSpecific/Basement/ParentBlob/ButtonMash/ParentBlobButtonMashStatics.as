import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonMash.ParentBlobButtonMashComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

delegate void FParentBlobButtonMashCompletedDelegate();

UFUNCTION()
void BindOnParentBlobButtonMashCompleted(AActor Actor, FParentBlobButtonMashCompletedDelegate Delegate)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

    UParentBlobButtonMashComponent ButtonMashComp = UParentBlobButtonMashComponent::GetOrCreate(ParentBlob);
    if (ButtonMashComp != nullptr)
    {
        ButtonMashComp.OnButtonMashCompleted.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
    }
}

UFUNCTION()
void StartParentBlobButtonMash()
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobButtonMashComponent ButtonMashComp = UParentBlobButtonMashComponent::GetOrCreate(ParentBlob);
	if (ButtonMashComp == nullptr)
		return;

	ButtonMashComp.ButtonMashStarted();
}

UFUNCTION()
void StopParentBlobButtonMash()
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobButtonMashComponent ButtonMashComp = UParentBlobButtonMashComponent::GetOrCreate(ParentBlob);
	if (ButtonMashComp == nullptr)
		return;

	ButtonMashComp.ButtonMashStopped();
}

UFUNCTION()
void StartParentBlobButtonMashInteraction(FTransform Transform)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobButtonMashComponent ButtonMashComp = UParentBlobButtonMashComponent::GetOrCreate(ParentBlob);
	if (ButtonMashComp == nullptr)
		return;

	ButtonMashComp.ButtonMashInteractionStarted(Transform);
}