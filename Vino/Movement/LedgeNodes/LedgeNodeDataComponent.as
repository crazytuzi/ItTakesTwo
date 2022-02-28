import Vino.Movement.LedgeNodes.LedgeNodeNames;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.LedgeNodes.LedgeNodeGrabSettings;

enum ECharacterLedgeNodeState
{
	None,
	Grabbing,
	Hang,
}

class ULedgeNodeDataComponent : UActorComponent
{
	ECharacterLedgeNodeState CurrentState = ECharacterLedgeNodeState::None;
	bool bCurrentStateIsDone = false;

	TArray<UHazeLedgeNodeBaseComponent> PotentialNodes;

	UHazeLedgeNodeBaseComponent TargetNode = nullptr;
	UHazeMovementComponent MoveComp = nullptr;

	float DisableTimer = 0.f;

	AHazeActor HazeOwner = nullptr;
	FLedgeNodeGrabSettings Settings;

	bool bDebugIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
		HazeOwner = Cast<AHazeActor>(Owner);
		ensure(HazeOwner != nullptr);

		MoveComp = UHazeMovementComponent::Get(HazeOwner);
	}

	void SetActiveLedgeNodeState(ECharacterLedgeNodeState StateToSet)
	{
		CurrentState = StateToSet;
		bCurrentStateIsDone = false;
	}

	bool IsCurrentState(ECharacterLedgeNodeState StateToCheck)
	{
		return CurrentState == StateToCheck;
	}

	bool IsStateDone(ECharacterLedgeNodeState StateToCheck)
	{
		if (CurrentState == StateToCheck)
			return bCurrentStateIsDone;

		return false;
	}

	void FlagStateAsDone(ECharacterLedgeNodeState StateToFlag)
	{
		ensure(CurrentState == StateToFlag);
		bCurrentStateIsDone = true;
	}

	bool HasValidTarget() const
	{
		return TargetNode != nullptr;
	}

	void SetDebugState(bool bNewDebugState)
	{
		if (bDebugIsActive != bNewDebugState)
		{
			for (auto Node : PotentialNodes)
			{
				Node.SetDebugState(bNewDebugState);
			}
		}

		bDebugIsActive = bNewDebugState;
	}

	void SetTarget(UHazeLedgeNodeBaseComponent NewTarget)
	{
		TargetNode = NewTarget;
	}

	FVector GetTargetHangLocation(FVector PlayerLocation)
	{
		if (!ensure(TargetNode != nullptr))
			return FVector::ZeroVector;

		return TargetNode.GetHangLocation(PlayerLocation, MoveComp.WorldUp);
	}

	FQuat GetTargetHangRotation()
	{
		if (!ensure(TargetNode != nullptr))
			return FQuat::Identity;

		return TargetNode.ComponentQuat;
	}

	void LeaveLedgeNode(AHazePlayerCharacter LeavingPlayer, ELedgeNodeLeaveType LeaveType)
	{
		float ResetDuration = Settings.JumpRentryDuration;
		if (LeaveType == ELedgeNodeLeaveType::Drop)
			ResetDuration = Settings.CancelDuration;

		TargetNode.OnLedgeNodeLetGo(LeavingPlayer, LeaveType);
		ResetTarget(ResetDuration);
	}

	private void ResetTarget(float DisableForDuration)
	{
		TargetNode = nullptr;
		SetActiveLedgeNodeState(ECharacterLedgeNodeState::None);

		if (DisableForDuration > 0.f)
		{
			DisableTimer = DisableForDuration;
			HazeOwner.BlockCapabilities(LedgeNodeTags::Grab, this);
			SetComponentTickEnabled(true);
		}
	}

	// When called on the remote side it sets target node, on the controlside it will 
	void SetAndVerifyTargetNode(UHazeLedgeNodeBaseComponent NewTargetNode)
	{
		if (!HasControl())
		{
			TargetNode = NewTargetNode;
		}
		else
		{
			devEnsure(TargetNode == NewTargetNode, "LedgeNode system is syncing the wrong targetnode");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DisableTimer -= DeltaTime;
		if (DisableTimer <= 0.f)
		{
			HazeOwner.UnblockCapabilities(LedgeNodeTags::Grab, this);
			SetComponentTickEnabled(false);
		}
	}

	void AddLedgeNode(UHazeLedgeNodeBaseComponent LedgeNode)
	{
		LedgeNode.SetDebugState(bDebugIsActive);
		PotentialNodes.AddUnique(LedgeNode);
	}

	void RemoveLedgeNode(UHazeLedgeNodeBaseComponent LedgeNode)
	{
		LedgeNode.SetDebugState(false);
		PotentialNodes.RemoveSwap(LedgeNode);
	}
}
