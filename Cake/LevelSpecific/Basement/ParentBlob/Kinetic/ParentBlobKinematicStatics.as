import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;


delegate void FParentBlobButtonKinematicCompletedDelegate(FParentBlobKineticInteractionCompletedDelegateData Data);

UFUNCTION(Category = "ParentBlob")
void BindOnParentBlobKinematicCompleted(AHazeActor Actor, FParentBlobButtonKinematicCompletedDelegate Delegate, FName OptionalComponentName = NAME_None)
{
    auto KinematicComponent = UParentBlobKineticInteractionComponent::Get(Actor, OptionalComponentName);
	if(KinematicComponent == nullptr)
		return;

	KinematicComponent.OnCompleted.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}
