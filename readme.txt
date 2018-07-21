Git init
Git status
Git add -A
Git log
Git commit -m "texto"

git commit -am "texto"

git reset --soft (volta ao estado antes do commit e mantem alteracoes)
git reset --mixed (igual ao soft mas percisa do add)
git reset --hard (Volta o que  era antes)

git checkout 20180716 ( mudar de branch )
git branch (mostra em qual branch esta)


git diff (ver as difrencas...o q foi incluido/alterado)

git diff --name-only (mostra os arquivos alterados)

git diff readme.txt (para ver as alteracoes de um arquivo especifico)

git checkout HEAD -- readme.txt (volta ao estado original)


No git bash:
 ssh-keygen -t rsa -b 4096 -C "otavio.bigboss@gmail.com" (para criar a KEY)
 No diretorio criado pelo git: c/Users/Otavio/.ssh', sera criada a chave "id_rsa.pub"

 Abrir este arquivo com bloco de notas , Ctrl+A e Ctrl+C 

 No acesso remoto copiar a chave e digitar um titulo... confirmar.

 Ja esta com o acesso sincronizado com a base loca.


** Para subir para a nuvem (remoto) **
git add -A
git commit -am "Atualizando o README mais um vez"

git push origin master


git revert --no-edit 23b7206a0e4f7268065ad178819c066bca6f138d



