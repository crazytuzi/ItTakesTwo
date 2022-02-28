import Vino.PlayerHealth.PlayerHealthComponent;

class UTriggerUserComponent : UHazeTriggerUserComponent
{
	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;

	TArray<UObject> InstigatorsPreventingActivation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	UHazeTriggerComponent SelectFocusedTrigger(const TArray<UHazeTriggerComponent>& Triggers) const
	{
		if (Player == nullptr)
			return nullptr;

		UHazeTriggerComponent ClosestTrigger = nullptr;
		float ClosestDistance = MAX_flt;

		for(UHazeTriggerComponent Trigger : Triggers)
		{
			FVector WorldPos = Trigger.WorldTransform.TransformPosition(Trigger.VisualOffset.Location);

			FVector2D ScreenPos;
			if(!SceneView::ProjectWorldToViewpointRelativePosition(Player, WorldPos, ScreenPos))
				continue;

			float Distance = ScreenPos.Distance(FVector2D(0.5f, 0.5f));
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestTrigger = Trigger;
			}
		}

		return ClosestTrigger;
	}

	UFUNCTION(BlueprintOverride)
	bool CanActivateTrigger(UHazeTriggerComponent Trigger, bool bForVisuals) const
	{
		if (HealthComp.bIsDead)
			return false;
		if (!bForVisuals && InstigatorsPreventingActivation.Num() != 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		InstigatorsPreventingActivation.Empty();
	}
};