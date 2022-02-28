struct FTrajectoryDataStruct
{
    FVector StartLocation;
    float TrajectoryLength;
    FVector Velocity;
    float Gravity;
    float Radius;
    FLinearColor Color;
	AHazePlayerCharacter PlayerToRenderFor;
	float NumberOfSegments;
	float DistanceBetweenSegments;
	bool bTrajectoryIsValid;
};

class UTrajectoryDrawer : USceneComponent
{
	UPROPERTY()
	UStaticMesh TrajectoryMesh = Asset("/Game/GUI/Trajectory/HighPolyCylinder.HighPolyCylinder");

	UPROPERTY()
	UMaterial TrajectoryMat = Asset("/Game/GUI/Trajectory/Trajectory.Trajectory");

	UPROPERTY()
	ETickingGroup TickingGroup = ETickingGroup::TG_PostPhysics;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
        SetTickGroup(TickingGroup);
    }

    TArray<FTrajectoryDataStruct> TractoryData;
    TArray<UStaticMeshComponent> Trajectories;
    TArray<UMaterialInstanceDynamic> TrajectoryMaterials;
	
    UFUNCTION(Category = "Trajectory|Drawing")
    void DrawTrajectory(
		FVector StartLocation, 
		float TrajectoryLength, 
		FVector Velocity, 
		float Gravity, 
		float Radius, 
		FLinearColor Color, 
		AHazePlayerCharacter Player = nullptr, 
		float NumberOfSegments = 20.0f, 
		float DistanceBetweenSegments = 0.5f,
		bool bTrajectoryIsValid = true)
    {
        FTrajectoryDataStruct data = FTrajectoryDataStruct();
        data.StartLocation = StartLocation;
        data.TrajectoryLength = TrajectoryLength;
        data.Velocity = Velocity;
        data.Gravity = Gravity;
        data.Radius = Radius;
        data.Color = Color;
		data.PlayerToRenderFor = Player;
        data.NumberOfSegments = NumberOfSegments;
        data.DistanceBetweenSegments = DistanceBetweenSegments;
		data.bTrajectoryIsValid = bTrajectoryIsValid;
        TractoryData.Add(data);
    }
    
    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
        while (TractoryData.Num() != Trajectories.Num())
        {
            if(TractoryData.Num() > Trajectories.Num())
            {
                // Too few components, add component.
                FString asdw = "" + Trajectories.Num();
                UStaticMeshComponent comp = UStaticMeshComponent::GetOrCreate(Cast<AHazeActor>(Owner), FName(asdw));
                comp.SetStaticMesh(TrajectoryMesh);
                comp.SetBoundsScale(10000000);
				comp.SetMaterial(0, TrajectoryMat);
                TrajectoryMaterials.Add(comp.CreateDynamicMaterialInstance(0));
                Trajectories.Add(comp);
            }
            else if(TractoryData.Num() < Trajectories.Num())
            {
                // Too many components, remove some.
                Trajectories[0].DestroyComponent(Owner);
                Trajectories.RemoveAt(0);
                TrajectoryMaterials.RemoveAt(0);
            }
        }
        
        for (int i = 0; i < Trajectories.Num(); i++)
        {
            if(TractoryData[i].PlayerToRenderFor == nullptr)
			{
				Trajectories[i].SetRenderedForPlayer(Game::GetCody(), true);
				Trajectories[i].SetRenderedForPlayer(Game::GetMay(), true);
			}
			else
			{
				auto OtherPlayer = TractoryData[i].PlayerToRenderFor == Game::GetCody() ? Game::GetMay() : Game::GetCody();
				Trajectories[i].SetRenderedForPlayer(OtherPlayer, false);
				Trajectories[i].SetRenderedForPlayer(TractoryData[i].PlayerToRenderFor, true);
			}

            Trajectories[i].SetWorldLocation(TractoryData[i].StartLocation);
			Trajectories[i].SetTranslucentSortPriority(20);
			
            TrajectoryMaterials[i].SetVectorParameterValue(n"Velocity", FLinearColor(TractoryData[i].Velocity.X, TractoryData[i].Velocity.Y, TractoryData[i].Velocity.Z, 0));
            TrajectoryMaterials[i].SetScalarParameterValue(n"Gravity", TractoryData[i].Gravity);
            TrajectoryMaterials[i].SetScalarParameterValue(n"TrajectoryLength", TractoryData[i].TrajectoryLength);
            TrajectoryMaterials[i].SetScalarParameterValue(n"Radius", TractoryData[i].Radius);
            TrajectoryMaterials[i].SetVectorParameterValue(n"Color", TractoryData[i].Color);
            TrajectoryMaterials[i].SetScalarParameterValue(n"NumberOfSegments", TractoryData[i].NumberOfSegments);
            TrajectoryMaterials[i].SetScalarParameterValue(n"DistanceBetweenSegments", TractoryData[i].DistanceBetweenSegments);
			TrajectoryMaterials[i].SetScalarParameterValue(n"IsValidTarget", TractoryData[i].bTrajectoryIsValid ? 1.f : 0.f);
        }

        TractoryData.Empty();
    }
}