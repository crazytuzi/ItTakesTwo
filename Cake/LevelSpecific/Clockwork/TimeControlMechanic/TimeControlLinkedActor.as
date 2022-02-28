import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

void OnPointTargeted(UTimeControlActorComponent TargetedComponent)
{
	ATimeControlLinkedActorsVolume Master = Cast<ATimeControlLinkedActorsVolume>(TargetedComponent.LinkedMaster);
	if(Master != nullptr)
	{
		if(Master.bCanTargetIndividualComponentsWhenLinked)
		{
			Master.TimeComponent.SetWorldLocation(TargetedComponent.GetWorldLocation());
		}
		Master.CurrentTargetedComponent = TargetedComponent;
	}
}

void OnPointTargetLost(UTimeControlActorComponent TargetedComponent)
{
	
}

// This actor will link all actors with the same time control settings as its own time component
class ATimeControlLinkedActorsVolume : AHazeEditorActorPicker 
{
	default RootComponent.SetWorldScale3D(FVector(3.f, 3.f, 3.f));
	default ComponentsToTrace.Add(UTimeControlActorComponent::StaticClass());

	UPROPERTY(DefaultComponent)
	UTimeControlActorComponent TimeComponent;

	UTimeControlActorComponent CurrentTargetedComponent;

	/* If true, you can target all the components individually and that will target the master component
	 * If false, you need to traget the master component to target all the indivual components
	*/
	UPROPERTY(Category = "Links")
	bool bCanTargetIndividualComponentsWhenLinked = true;

	UFUNCTION(BlueprintOverride)
	void OnActorGenerationClicked(const TArray<AActor>& FoundActors)
	{
		// Clean up the current links
		TimeComponent.UnlinkAllSlaves();
		if(bCanTargetIndividualComponentsWhenLinked)
		{
			TimeComponent.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}
		else
		{
			TimeComponent.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
		}

		for (AActor Actor : FoundActors)
		{
			UTimeControlActorComponent WantedLinkedTimeComp = UTimeControlActorComponent::Get(Actor);
			if(WantedLinkedTimeComp == nullptr)
				continue;
			else if(Actor == this)
				continue;
			else if(WantedLinkedTimeComp.bCanBeTimeControlled != TimeComponent.bCanBeTimeControlled)
				continue;

			WantedLinkedTimeComp.LinkWithMasterComponent(TimeComponent, bCanTargetIndividualComponentsWhenLinked);
		}

		FVector NewWorldPosition = TimeComponent.GenerateLinkedMiddlePosition();
		TimeComponent.SetWorldLocation(NewWorldPosition);
    }
}
