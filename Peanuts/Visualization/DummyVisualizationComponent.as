class UDummyVisualizationComponent : UActorComponent
{
	TArray<AActor> ConnectedActors;
	TArray<FVector> ConnectedLocalLocations;
	float DashSize = 20.f;
	FLinearColor Color = FLinearColor::White;

	USceneComponent ConnectionBase = nullptr;
	FVector ConnectionBaseOffset = FVector::ZeroVector;
}
