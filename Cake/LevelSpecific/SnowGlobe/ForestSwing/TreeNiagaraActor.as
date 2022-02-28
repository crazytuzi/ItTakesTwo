class ATreeNiagaraActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent TreeSystem;
	default TreeSystem.SetAutoActivate(false);

	void ActivateSystem()
	{
		Print("ActivateSystem");
		TreeSystem.Activate();
	} 
}