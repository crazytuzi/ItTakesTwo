import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;

class UTurretPlantSoilDummyVisualizerComponent : UActorComponent{}

#if EDITOR

class USubmersibleSoilTurretPlantVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UTurretPlantSoilDummyVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UTurretPlantSoilDummyVisualizerComponent Comp = Cast<UTurretPlantSoilDummyVisualizerComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			return;
		
		ASubmersibleSoilTurretPlant TurretPlantSoil = Cast<ASubmersibleSoilTurretPlant>(Comp.Owner);

		if(TurretPlantSoil.bUsePlayerRotation)
			return;

		const float Length = 600.0f;
		const float Height = 400.0f;
		const FVector Forward = FVector::ForwardVector.RotateAngleAxis(TurretPlantSoil.YawAngleStart, FVector::UpVector);
		const FVector StartLoc = TurretPlantSoil.ActorLocation + FVector::UpVector * Height;
		const FVector EndLoc = StartLoc + Forward * Length;
		DrawArrow(StartLoc, EndLoc, FLinearColor::Green, 50, 5);
	}
}

#endif // EDITOR

class ASubmersibleSoilTurretPlant : ASubmersibleSoil
{
	UPROPERTY(DefaultComponent, NotEditable)
	UTurretPlantSoilDummyVisualizerComponent Visualizer;
	default Visualizer.bIsEditorOnly = true;

	UPROPERTY()
	bool bUsePlayerRotation = true;

	UPROPERTY(meta = (EditCondition = "!bUsePlayerRotation", EditConditionHides, ClampMin = -180, ClampMax = 180))
	float YawAngleStart = 0;
}
