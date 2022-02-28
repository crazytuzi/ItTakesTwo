// import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.MagneticMoveableObjectConstrained;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetChimneyComponent;

// event void FOnChimneyLidStateChangedSignature(bool IsAtEnd, AMagneticMoveableObjectConstrainedChimney Object);
// class AMagneticMoveableObjectConstrainedChimney : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	UStaticMeshComponent Mesh;

// 	UPROPERTY(DefaultComponent, Attach = Mesh)
// 	UStaticMeshComponent PullLocation;

// 	UPROPERTY(DefaultComponent, Attach = Mesh)
// 	UStaticMeshComponent PushLocation;

// 	UPROPERTY(DefaultComponent, Attach = Mesh)
// 	UMagneticChimneyComponent MagnetChimneyComponent;

// 	UPROPERTY(DefaultComponent)
// 	UArrowComponent ForwardArrow;

// 	UPROPERTY()
// 	FOnChimneyLidStateChangedSignature OnLidIsOpenStateChanged;

// 	UPROPERTY()
// 	bool bReachedEnd = false;


// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		PullLocation.SetHiddenInGame(true);
// 		PushLocation.SetHiddenInGame(true);

// 		PullLocation.DetachFromParent(true, true);
// 		PushLocation.DetachFromParent(true, true);
// 	}
// }