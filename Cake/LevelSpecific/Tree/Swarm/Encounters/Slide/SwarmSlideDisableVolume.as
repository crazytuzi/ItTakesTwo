import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Peanuts.Triggers.HazeTriggerBase;

/*
	Will disable referenced (or overlapping) swarms when both players have left/entered the volume
*/ 

class ASwarmSlideDisableVolume : AHazeTriggerBase
{
	default BrushComponent.CollisionEnabled = ECollisionEnabled::QueryOnly;
	default BrushComponent.SetCollisionObjectType(ECollisionChannel::ECC_WorldStatic);
	default BrushComponent.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BrushComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default bGenerateOverlapEventsDuringLevelStreaming = false;

	// the volume will disable overlapping swarms IF this is left empty
	UPROPERTY()
	TArray<ASwarmActor> SwarmsToDisable;

	bool bHasEnteredVolume_May = false;
	bool bHasEnteredVolume_Cody = false;

	UPROPERTY()
	FLinearColor VolumeColor = FLinearColor::Blue;
	default BrushColor = VolumeColor;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript() 
	{
		Super::ConstructionScript();
		SetBrushColor(VolumeColor);
	}

    bool ShouldTrigger(AActor Actor) override
    {
        auto Player = Cast<AHazePlayerCharacter>(Actor);
        if (Player == nullptr)
            return false;

		return true;
    }

    void LeaveTrigger(AActor Actor) override
    {
		if(HasControl() == false)
			return;

		if(!bHasEnteredVolume_May && Actor == Game::GetMay())
			bHasEnteredVolume_May = true;

		if(!bHasEnteredVolume_Cody && Actor == Game::GetCody())
			bHasEnteredVolume_Cody = true;

		if(bHasEnteredVolume_Cody && bHasEnteredVolume_May)
			NetDisableReferencedSwarms();
	}

	UFUNCTION(NetFunction)
	void NetDisableReferencedSwarms()
	{
		if(SwarmsToDisable.Num() != 0)
		{
			for(ASwarmActor IterSwarm : SwarmsToDisable)
			{
				if(IterSwarm == nullptr)
					continue;
				
				IterSwarm.DisableActor(this);

				PrintToScreenScaled("Disabling Swarm: " + IterSwarm.GetName(), Duration = 3.f);
			}
		}
		else
		{
			DisableOverlappingSwarms();
		}

		SetTriggerEnabled(false);
	}

	void DisableOverlappingSwarms()
	{
		UHazeAITeam SwarmTeam = HazeAIBlueprintHelper::GetTeam(n"SwarmTeam");

		for(AHazeActor TeamMember : SwarmTeam.GetMembers())
		{
			if(TeamMember == nullptr)
				continue;

			ASwarmActor SwarmIter = Cast<ASwarmActor>(TeamMember);

			if (SwarmIter == nullptr)
				continue;

			if (SwarmIter.IsDead())
				continue;

			// ignore the slide swarm that deploys all poseables
			if(SwarmIter.SkelMeshComp.GetMobility() == EComponentMobility::Movable )
				continue;

			// both the volume and the swarms are stationary 
			// so this should be safe in network as well.
			if(IsOverlappingSwarm(SwarmIter))
			{
				PrintToScreen("Disabling Overlapping Swarm: " + SwarmIter.GetName(), Duration = 3.f);
				SwarmIter.DisableActor(this);
			}
		}
	}

	bool IsOverlappingSwarm(ASwarmActor InSwarm)
	{
		TArray<UPrimitiveComponent> Prims;
		InSwarm.GetComponentsByClass(Prims);
		for(UPrimitiveComponent IterPrim : Prims)
		{
			if(!IterPrim.IsCollisionEnabled())
				continue;

			if(Trace::ComponentOverlapComponent(
				BrushComponent,
				IterPrim,
				IterPrim.GetWorldLocation(),
				IterPrim.GetComponentQuat(),
				bTraceComplex = false
			))
			{
				return true;
			}
		}

		return false;
	}

}