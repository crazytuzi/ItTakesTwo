import Vino.Movement.LedgeNodes.LedgeNodeDataComponent;
import Vino.Movement.LedgeNodes.LedgeNodeGrabSettings;

delegate void FPlayerGrabbedLedgeNodeDelegate(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter GrabbingPlayer);
event void FPlayerGrabbedLedgeNodeEvent(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter GrabbingPlayer);

delegate void FPlayerLeftLedgeNodeDelegate(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter LeavingPlayer, ELedgeNodeLeaveType LeaveType);
event void FPlayerLeftLedgeNodeEvent(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter LeavingPlayer, ELedgeNodeLeaveType LeaveType);

UFUNCTION()
void BindOnLedgeNodeGrabbed(AHazeActor GrabbedActor, FPlayerGrabbedLedgeNodeDelegate Delegate)
{
	if(GrabbedActor == nullptr)
		return;

	ULedgeNodeComponent Comp = ULedgeNodeComponent::Get(GrabbedActor);
	if (!devEnsure(Comp != nullptr, GrabbedActor.Name + ": Trying to bind LedgeNodeGrabbed on a actor that doesn't have a LedgeNodeComponent"))
		return;
	
	Comp.LedgeNodeGrabbedCallback.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}

UFUNCTION()
void BindOnLedgeNodeLetGo(AHazeActor GrabbedActor, FPlayerLeftLedgeNodeDelegate Delegate)
{
	if(GrabbedActor == nullptr)
		return;
	
	ULedgeNodeComponent Comp = ULedgeNodeComponent::Get(GrabbedActor);
	if (!devEnsure(Comp != nullptr, GrabbedActor.Name + ": Trying to bind LedgeNodeLetGo on a actor that doesn't have a LedgeNodeComponent"))
		return;
	
	Comp.LedgeNodeLetGoCallback.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}

enum ELedgeNodeUserType
{
	Cody,
	May,
	Both,
}

class ULedgeNodeComponent : UHazeLedgeNodeBaseComponent
{
	FLedgeNodeGrabSettings Settings;

	FPlayerGrabbedLedgeNodeEvent LedgeNodeGrabbedCallback;
	FPlayerLeftLedgeNodeEvent LedgeNodeLetGoCallback;

	UPROPERTY(Category = "LedgeNodes")
	protected ELedgeNodeUserType UserType = ELedgeNodeUserType::Both;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnBeginOverlap(AHazePlayerCharacter OverlapPlayer)
	{
		if (OverlapPlayer.IsCody() && UserType == ELedgeNodeUserType::May)
			return;

		if (OverlapPlayer.IsMay() && UserType == ELedgeNodeUserType::Cody)
			return;

		ULedgeNodeDataComponent DataComponent = ULedgeNodeDataComponent::GetOrCreate(OverlapPlayer);
		DataComponent.AddLedgeNode(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnEndOverlap(AHazePlayerCharacter OverlapPlayer)
	{
		if (OverlapPlayer.IsCody() && UserType == ELedgeNodeUserType::May)
			return;

		if (OverlapPlayer.IsMay() && UserType == ELedgeNodeUserType::Cody)
			return;

		ULedgeNodeDataComponent DataComponent = ULedgeNodeDataComponent::GetOrCreate(OverlapPlayer);
		DataComponent.RemoveLedgeNode(this);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetHangLocation(FVector PlayerLocation, FVector WorldUp) const
	{
		FVector LedgePoint = GetNodeLocation(PlayerLocation);

		FVector Up = WorldUp.IsNearlyZero() ? UpVector : WorldUp;
		return LedgePoint - (Up * Settings.HangOffset);
	}

	UFUNCTION(BlueprintOverride)
	void OnLedgeNodeGrabbed(AHazePlayerCharacter GrabbingPlayer)
	{
		if (GrabbingPlayer == nullptr)
			return;

		LedgeNodeGrabbedCallback.Broadcast(this, GrabbingPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnLedgeNodeLetGo(AHazePlayerCharacter LeavingPlayer, ELedgeNodeLeaveType LeaveType)
	{
		if (LeavingPlayer == nullptr)
			return;

		LedgeNodeLetGoCallback.Broadcast(this, LeavingPlayer, LeaveType);
	}
}
