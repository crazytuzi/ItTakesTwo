import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

#if EDITOR
class UIceSkatingMagnetSwingVisualizerComponent : UActorComponent { } 

class UIceSkatingMagnetSwingVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIceSkatingMagnetSwingVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		AIceSkatingMagnetSwing Swing = Cast<AIceSkatingMagnetSwing>(Component.Owner);
        if (!ensure(Swing != nullptr))
            return;

		DrawWireSphere(Swing.RedMagnet.WorldLocation, Swing.ActivateRadius, FLinearColor::Green, Segments = 20);
		DrawWireSphere(Swing.RedMagnet.WorldLocation, Swing.TargetRadius, FLinearColor::Yellow, Segments = 20);
		DrawWireSphere(Swing.RedMagnet.WorldLocation, Swing.VisibleRadius, FLinearColor::Red, Segments = 20);
	}
}
#endif

class AIceSkatingMagnetSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMagneticComponent RedMagnet;

	UPROPERTY(DefaultComponent)
	UMagneticComponent BlueMagnet;

#if EDITOR
	UPROPERTY(DefaultComponent, NotVisible)
	UIceSkatingMagnetSwingVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(Category = "Swing")
	float ActivateRadius = 800.f;

	UPROPERTY(Category = "Swing")
	float TargetRadius = 1000.f;

	UPROPERTY(Category = "Swing")
	float VisibleRadius = 1200.f;

	UPROPERTY(Category = "Swing")
	float Force = 6000.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RedMagnet.InitializeDistance(EHazeActivationPointDistanceType::Targetable, TargetRadius);
		RedMagnet.InitializeDistance(EHazeActivationPointDistanceType::Selectable, ActivateRadius);
		RedMagnet.InitializeDistance(EHazeActivationPointDistanceType::Visible, VisibleRadius);

		BlueMagnet.InitializeDistance(EHazeActivationPointDistanceType::Targetable, TargetRadius);
		BlueMagnet.InitializeDistance(EHazeActivationPointDistanceType::Selectable, ActivateRadius);
		BlueMagnet.InitializeDistance(EHazeActivationPointDistanceType::Visible, VisibleRadius);
	}
}