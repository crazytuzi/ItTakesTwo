
class UClockworkTimelineMovingObjectRootComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = true;
	default SetComponentTickInterval(0.f);

	UPROPERTY(EditInstanceOnly, meta = (InlineEditConditionToggle), Category = "Activation")
	bool bDisableIfNotRendered = true;

	UPROPERTY(EditConst, Category = "Activation", meta = (EditCondition = "bDisableIfNotRendered"))
	UPrimitiveComponent DisableIfNotRendered;

	UPROPERTY(EditConst, Category = "Activation")
	UHazeDisableComponent DisableComponent;

	UPROPERTY(EditConst, Category = "Activation")
	bool bIsLinked = false;

	bool bHasDisabledActor = false;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		if(DisableIfNotRendered != nullptr)
		{
			DisableComponent = UHazeDisableComponent::Get(Owner);
			devEnsure(DisableComponent != nullptr, "Cant use bDisableIfNotRendered on" + Owner.GetName() + " since there is no HazeDisableComponent");
			devEnsure(DisableComponent.bRenderWhileDisabled, "Cant use bDisableIfNotRendered on " + Owner.GetName() + " since the disable component will stop render the " + DisableIfNotRendered.GetName());
		}

		if(!bDisableIfNotRendered && DisableComponent != nullptr)
		{
			DisableComponent.bAutoDisable = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// This component cant be disabled
		return true;
	}

	UFUNCTION()
	void MakeDisableIfNotRendered(UPrimitiveComponent Component)
	{
		if(DisableIfNotRendered != nullptr && Component == nullptr && bHasDisabledActor)
		{
			bHasDisabledActor = false;
			Cast<AHazeActor>(Owner).EnableActor(this);
		}
		DisableIfNotRendered = Component;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bDisableIfNotRendered && DisableIfNotRendered != nullptr)
		{
			if(DisableComponent == nullptr || !DisableComponent.bAutoDisable || DisableComponent.bIsAutoDisabled)
			{
				bool bShouldBeDisabled = !DisableIfNotRendered.WasRecentlyRendered();
				if(bShouldBeDisabled && !bHasDisabledActor)
				{
					bHasDisabledActor = true;
					Cast<AHazeActor>(Owner).DisableActor(this);
				}
				else if(!bShouldBeDisabled && bHasDisabledActor)
				{
					bHasDisabledActor = false;
					Cast<AHazeActor>(Owner).EnableActor(this);
				}
			}
		}
	}
}