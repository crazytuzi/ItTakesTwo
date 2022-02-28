import Peanuts.Spline.SplineComponent;
import Effects.PostProcess.PostProcessing;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Peanuts.Fades.FadeStatics;

event void FFearCrawlerEvent();

UCLASS(Abstract)
class AFearCrawler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase CrawlerMesh;

	UPROPERTY()
	float MovementSpeed = 2000.f;

	UHazeSplineComponent TargetFollowSpline;
	bool bFollowingSpline = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}
}