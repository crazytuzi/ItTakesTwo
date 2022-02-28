import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;
import Vino.Checkpoints.Volumes.DeathVolume;

class UBeanstalkSoilDummyVisualizerComponent : UActorComponent{}

#if EDITOR

class USubmersibleSoilBeanstalkVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UBeanstalkSoilDummyVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UBeanstalkSoilDummyVisualizerComponent Comp = Cast<UBeanstalkSoilDummyVisualizerComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			return;
		
		ASubmersibleSoilBeanstalk BeanstalkSoil = Cast<ASubmersibleSoilBeanstalk>(Comp.Owner);

		if(BeanstalkSoil.bOverrideMaxHeight)
		{
			DrawArrow(BeanstalkSoil.ActorLocation, BeanstalkSoil.ActorLocation + FVector(0, 0, BeanstalkSoil.BeanstalkMaxHeight), FLinearColor::Green, 20, 10);
		}

		if(BeanstalkSoil.bOverrideMinHeight)
		{
			DrawArrow(BeanstalkSoil.ActorLocation, BeanstalkSoil.ActorLocation + FVector(0, 0, -BeanstalkSoil.BeanstalkMinHeight), FLinearColor::Green, 20, 10);
		}
	}
}

#endif // EDITOR

class UBeanstalkSplineRegion : UHazeSplineRegionComponent
{

}

class ASubmersibleSoilBeanstalk : ASubmersibleSoil
{	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent EmergeSplinePath;

	UPROPERTY(DefaultComponent, Attach = EmergeSplinePath)
	UHazeSplineRegionContainerComponent SplineRegionContainer;

	UPROPERTY(DefaultComponent, Attach = SplineRegionContainer)
	UBeanstalkSplineRegion SplineRegion;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SplineRegionContainer.RegisteredRegionTypes.Empty();
		SplineRegionContainer.RegisteredRegionTypes.Add(UBeanstalkSplineRegion::StaticClass());
	}

	
	// Select death volumes to disable (for cody) whenever he transforms into the beanstalk.
	UPROPERTY()
	TArray<ADeathVolume> DeathVolumeCollection;
	
	UPROPERTY()
	bool bOverrideMaxLength = false;
	
	UPROPERTY(meta = (EditCondition = "bOverrideMaxLength", EditConditionHides))
	float BeanstalkMaxLength = 8000.0f;

	UPROPERTY()
	bool bOverrideMaxHeight = false;

	UPROPERTY(meta = (EditCondition = "bOverrideMaxHeight", EditConditionHides, ClampMin = 0))
	float BeanstalkMaxHeight = 6000.0f;

	UPROPERTY()
	bool bOverrideMinHeight = false;

	UPROPERTY(meta = (EditCondition = "bOverrideMinHeight", EditConditionHides, ClampMin = 0))
	float BeanstalkMinHeight = 6000.0f;

	// Check this and the beanstalk will use the location of your choice as start location.
	UPROPERTY()
	bool bOverrideStartingLocation = false;

	UPROPERTY(meta = (EditCondition = "bTopView", EditConditionHides, ClampMin = -180, ClampMax = 180))
	float CameraYaw = 0.0f;

	UPROPERTY(meta = (EditCondition = "bOverrideStartingLocation", EditConditionHides, MakeEditWidget))
	FVector StartLocation;

	FVector GetOverrideStartingLocation() const property
	{
		return ActorTransform.TransformPosition(StartLocation);
	}

	void DisableDeathVolumes()
	{
		for(ADeathVolume DeathVolume : DeathVolumeCollection)
		{
			if(DeathVolume == nullptr)
				continue;

			DeathVolume.bKillsCody = false;
		}
	}

	void EnableDeathVolumes()
	{
		for(ADeathVolume DeathVolume : DeathVolumeCollection)
		{
			if(DeathVolume == nullptr)
				continue;
				
			DeathVolume.bKillsCody = true;
		}
	}

	FVector GetSpawnLocation() const property
	{
		return EmergeSplinePath.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World);
	}

	UPROPERTY(DefaultComponent, NotEditable)
	UBeanstalkSoilDummyVisualizerComponent Visualizer;
	default Visualizer.bIsEditorOnly = true;
}
