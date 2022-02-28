import Cake.Environment.GameplayUnwitherSphere;

class AGardenUnwitherSphereManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = "Billboard")
	UTextRenderComponent ManagerText;
	default ManagerText.SetText(FText::FromString("Unwither Sphere Manager"));
	default ManagerText.SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
	default ManagerText.SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
	default ManagerText.SetHiddenInGame(true);
	default ManagerText.XScale = 5;
	default ManagerText.YScale = 5;

	UPROPERTY()
	TArray<AGameplayUnwitherSphereActor> UnwitherSpheres;
}
