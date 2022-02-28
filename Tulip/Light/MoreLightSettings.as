class UMoreLightSettingsComponent : UActorComponent
{
	// Low = Always Enabled, Medium = Disabled on low, High = High only.
	UPROPERTY()
	EDetailMode CastDynamicShadowsDetailMode;
	
	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		UActorComponent Comp = Owner.GetComponentByClass(ULightComponent::StaticClass());

		if(Comp == nullptr)
			return;
		
		ULightComponent LightComp = Cast<ULightComponent>(Comp);
		
		if(LightComp == nullptr)
			return;

		bool Enabled = false;
		if(CastDynamicShadowsDetailMode == EDetailMode::DM_Low)
		{
			Enabled = true;
		}
		else if(CastDynamicShadowsDetailMode == EDetailMode::DM_Medium)
		{
			if(Game::DetailModeMedium)
				Enabled = true;
			else if(Game::DetailModeHigh)
				Enabled = true;
		}
		else if(CastDynamicShadowsDetailMode == EDetailMode::DM_High)
		{
			if(Game::DetailModeHigh)
				Enabled = true;
		}
		
		Light::SetDynamicShadows(LightComp, Enabled);
	}
}

