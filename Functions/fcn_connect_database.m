function conn = fcn_connect_database(server_flag)
    if server_flag
        
        % Add class path (if not in the class path)  
        DB.p = '/opt/routing/nevo/postgresql-42.1.4.jar';  
        if ~ismember(DB.p,javaclasspath)
            javaaddpath(DB.p);
        end
        
        % Database connection
        database_variables_server;
        conn           = database(DB.datasource,DB.username,DB.password,DB.driver,DB.url,'ErrorHandling', 'report');
        % clear DB;
        
    else
        
        % Add class path (if not in the class path)
        DB.p = 'C:\Program Files\PostgreSQL\postgresql-42.0.0.jre7.jar'; 
        if ~ismember(DB.p,javaclasspath)  
           javaaddpath(DB.p)  
        end
        
        % Database connection

        database_variables_local;
        conn           = database(DB.datasource,DB.username,DB.password,DB.driver,DB.url,'ErrorHandling', 'report');
        
    end

end