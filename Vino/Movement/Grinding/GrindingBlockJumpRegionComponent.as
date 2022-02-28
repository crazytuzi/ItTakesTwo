import Vino.Movement.Grinding.GrindingReasons;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.GrindingBaseRegionComponent;

class UGrindingBlockJumpRegionComponent : UGrindingBaseRegionComponent
{
	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Red;
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor ActorEntering)
	{
		ActorEntering.BlockCapabilities(GrindingCapabilityTags::Jump, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionExit(AHazeActor LeavingActor, ERegionExitReason ExitReason)
	{
		LeavingActor.UnblockCapabilities(GrindingCapabilityTags::Jump, this);
	}
}

