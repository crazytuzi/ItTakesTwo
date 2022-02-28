import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

UCLASS(HideCategories = "Niagara OverrideParameters Physics Collision ComponentReplication LOD Mobile")
class UMagnetNiagaraComponent : UNiagaraComponent
{
	UPROPERTY(Category = "Color Specific Systems")
	private UNiagaraSystem Positive_RedSystem;

	UPROPERTY(Category = "Color Specific Systems")
	private UNiagaraSystem Negative_BlueSystem;

	void InitializePolarity(EMagnetPolarity Polarity)
	{
		if(Polarity == EMagnetPolarity::Plus_Red)
			Asset = Positive_RedSystem;
		else
			Asset = Negative_BlueSystem;
	}

	void Play()
	{
		if(IsActive())
			ReinitializeSystem();
		else
			Activate();

		OnSystemFinished.AddUFunction(this, n"OnEffectFinished");
	}

	void Stop()
	{
		Deactivate();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnEffectFinished(UNiagaraComponent NiagaraComponent)
	{
		Deactivate();
		OnSystemFinished.UnbindObject(this);
	}
}